import 'dart:convert';

import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/core/utils/subscription_codec.dart';
import 'package:tradefy_vpn/core/utils/xray_config.dart';
import 'package:tradefy_vpn/data/models/vpn_node.dart';

class SubscriptionService {
  SubscriptionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _supportedSchemes = <String>[
    'vless://',
    'vmess://',
    'trojan://',
    'ss://',
    'socks://',
    'hysteria2://',
    'hy2://',
    'wireguard://',
  ];

  Future<List<VpnNode>> fetchNodes() async {
    final specialLinks = await _fetchLinks(AppConfig.specialSubscriptionUrl);
    final regularLinks = <String>[];
    for (final url in AppConfig.subscriptionUrls) {
      regularLinks.addAll(await _fetchLinks(url));
    }

    final unique = <String>{};
    final nodes = <VpnNode>[];
    for (final link in specialLinks) {
      final node = _addUnique(link, unique, special: true);
      if (node != null) nodes.add(node);
    }
    for (final link in regularLinks) {
      final node = _addUnique(link, unique, special: false);
      if (node != null) nodes.add(node);
    }
    return nodes;
  }

  Future<List<String>> _fetchLinks(String url) async {
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: <String, String>{
              'User-Agent': AppConfig.userAgent,
              'Accept': 'text/plain,*/*',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <String>[];
      }
      return _extractShareLinks(decodeSubscriptionBody(response.body));
    } catch (_) {
      return const <String>[];
    }
  }

  VpnNode? _addUnique(String link, Set<String> unique, {required bool special}) {
    final normalized = _normalizeLink(link);
    if (!unique.add(normalized)) return null;
    return _parseShareLink(link, special: special);
  }

  List<String> _extractShareLinks(String body) {
    final links = <String>[];
    for (final rawLine in body.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final lower = line.toLowerCase();
      if (_supportedSchemes.any(lower.startsWith)) {
        links.add(line);
      }
    }
    return links;
  }

  String _normalizeLink(String link) {
    final withoutFragment = link.split('#').first;
    return withoutFragment.trim();
  }

  VpnNode? _parseShareLink(String link, {required bool special}) {
    final sanitized = sanitizeShareLink(link);
    for (final candidate in <String>[sanitized, link]) {
      try {
        return _parseCandidate(
          original: link,
          candidate: candidate,
          special: special,
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  VpnNode _parseCandidate({
    required String original,
    required String candidate,
    required bool special,
  }) {
    final remark = special
        ? AppConfig.specialNodeDisplayName
        : AppConfig.nodeDisplayName;
    final renamed = _withRemark(candidate, remark);
    final parsed = V2ray.parseFromURL(renamed);
    parsed.inbound['port'] = 10808;
    final configJson = optimizeXrayConfig(
      parsed.getFullConfiguration(),
      shareLink: original,
    );
    return VpnNode(
      id: _nodeId(sanitizeShareLink(original)),
      shareLink: renamed,
      configJson: configJson,
      protocol: _protocolFromLink(original),
      address: parsed.address.isEmpty
          ? _endpointFromLink(original).$1
          : parsed.address,
      port: parsed.port,
      pingMs: AppConfig.delayFailureMs,
      countryCode: special ? 'US' : '',
      country: special ? 'United States' : 'نامشخص',
      isSpecial: special,
    );
  }

  String _withRemark(String link, String remark) {
    final encoded = Uri.encodeComponent(remark);
    final hash = link.indexOf('#');
    if (hash >= 0) {
      return '${link.substring(0, hash)}#$encoded';
    }
    return '$link#$encoded';
  }

  String _protocolFromLink(String link) {
    final scheme = link.split('://').first.toLowerCase();
    return scheme;
  }

  (String, int) _endpointFromLink(String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.host.isNotEmpty) {
        return (uri.host, uri.hasPort ? uri.port : 443);
      }
    } catch (_) {}

    final withoutScheme = link.split('://').skip(1).join('://');
    final withoutFragment = withoutScheme.split('#').first;
    final withoutQuery = withoutFragment.split('?').first;
    final at = withoutQuery.lastIndexOf('@');
    final hostPort = at >= 0 ? withoutQuery.substring(at + 1) : withoutQuery;
    final parts = hostPort.split(':');
    if (parts.length >= 2) {
      return (parts.first, int.tryParse(parts.last) ?? 443);
    }
    return (hostPort, 443);
  }

  String _nodeId(String link) {
    return base64Url.encode(utf8.encode(_normalizeLink(link))).replaceAll('=', '');
  }
}
