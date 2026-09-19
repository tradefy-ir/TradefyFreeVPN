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
    final collected = <String>[];
    for (final url in AppConfig.subscriptionUrls) {
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
          continue;
        }
        collected.addAll(_extractShareLinks(decodeSubscriptionBody(response.body)));
      } catch (_) {
        continue;
      }
    }

    final unique = <String>{};
    final nodes = <VpnNode>[];
    for (final link in collected) {
      final normalized = _normalizeLink(link);
      if (!unique.add(normalized)) continue;
      final node = _parseShareLink(link);
      if (node != null) nodes.add(node);
    }
    return nodes;
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

  VpnNode? _parseShareLink(String link) {
    final sanitized = sanitizeShareLink(link);
    for (final candidate in <String>[sanitized, link]) {
      try {
        return _parseCandidate(original: link, candidate: candidate);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  VpnNode _parseCandidate({required String original, required String candidate}) {
    final renamed = _withRemark(candidate, AppConfig.nodeDisplayName);
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
      countryCode: '',
      country: 'نامشخص',
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
