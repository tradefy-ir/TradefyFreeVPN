import 'dart:convert';

/// Align share-link JSON with V2rayNG-style routing/DNS for delay tests
/// and as the base config before [applyVpnRuntimeSettings].
String optimizeXrayConfig(String configJson, {String? shareLink}) {
  final decoded = jsonDecode(configJson);
  if (decoded is! Map) return configJson;
  final config = Map<String, dynamic>.from(decoded);

  config['log'] = <String, dynamic>{
    ...Map<String, dynamic>.from((config['log'] as Map?) ?? <String, dynamic>{}),
    'loglevel': 'warning',
  };

  config['dns'] = <String, dynamic>{
    'queryStrategy': 'UseIPv4',
    'servers': <dynamic>['1.1.1.1', '8.8.8.8'],
  };

  final routing = Map<String, dynamic>.from(
    (config['routing'] as Map?) ?? <String, dynamic>{},
  );
  routing['domainStrategy'] = 'AsIs';
  routing['rules'] = routing['rules'] ?? <dynamic>[];
  config['routing'] = routing;

  final inbounds = (config['inbounds'] as List?) ?? <dynamic>[];
  config['inbounds'] = [
    for (final inbound in inbounds)
      if (inbound is Map)
        <String, dynamic>{
          ...Map<String, dynamic>.from(inbound),
          'port': inbound['protocol'] == 'socks' ? 10808 : inbound['port'],
          'listen': inbound['listen'] ?? '127.0.0.1',
          'sniffing': <String, dynamic>{
            'enabled': false,
            'routeOnly': false,
          },
        }
      else
        inbound,
  ];

  final outbounds = (config['outbounds'] as List?) ?? <dynamic>[];
  config['outbounds'] = [
    for (final outbound in outbounds)
      if (outbound is Map)
        _optimizeOutbound(Map<String, dynamic>.from(outbound))
      else
        outbound,
  ];

  if (shareLink != null) {
    _applyDecodedCredentials(config, shareLink);
  }

  return const JsonEncoder.withIndent('  ').convert(config);
}

/// Compact JSON for VpnService start. Do not switch to fakeDNS or tunneled
/// DNS here — that either poisons the proxy hostname or deadlocks DNS.
String applyVpnRuntimeSettings(String configJson) {
  final decoded = jsonDecode(configJson);
  if (decoded is! Map) return configJson;
  final config = Map<String, dynamic>.from(decoded);
  config.remove('fakedns');
  return jsonEncode(config);
}

Map<String, dynamic> _optimizeOutbound(Map<String, dynamic> outbound) {
  final stream = Map<String, dynamic>.from(
    (outbound['streamSettings'] as Map?) ?? <String, dynamic>{},
  );
  _normalizeWsSettings(stream);

  final sockopt = Map<String, dynamic>.from(
    (stream['sockopt'] as Map?) ?? <String, dynamic>{},
  );
  sockopt['tcpNoDelay'] = true;
  sockopt['tcpFastOpen'] = false;
  if (outbound['protocol'] == 'freedom') {
    sockopt['domainStrategy'] = 'AsIs';
  }
  stream['sockopt'] = sockopt;
  outbound['streamSettings'] = stream;

  final mux = outbound['mux'];
  if (mux is Map) {
    outbound['mux'] = <String, dynamic>{
      ...Map<String, dynamic>.from(mux),
      'enabled': false,
    };
  }

  if (outbound['protocol'] == 'trojan') {
    _stripTrojanShadowsocksFields(outbound);
  }
  return outbound;
}

void _normalizeWsSettings(Map<String, dynamic> stream) {
  final raw = stream['wsSettings'];
  if (raw is! Map) return;
  final ws = Map<String, dynamic>.from(raw);
  final headers = ws['headers'];
  if (headers is Map) {
    final host = headers['Host'] ?? headers['host'];
    if (host is String && host.isNotEmpty) {
      ws['host'] = host;
    }
  }
  final path = ws['path'];
  if (path is List && path.isNotEmpty) {
    ws['path'] = path.first;
  }
  stream['wsSettings'] = ws;
}

void _stripTrojanShadowsocksFields(Map<String, dynamic> outbound) {
  final settings = outbound['settings'];
  if (settings is! Map) return;
  final servers = settings['servers'];
  if (servers is! List) return;
  final cleaned = <dynamic>[];
  for (final server in servers) {
    if (server is Map) {
      final copy = Map<String, dynamic>.from(server);
      copy.remove('method');
      copy.remove('ota');
      copy.remove('ivCheck');
      cleaned.add(copy);
    } else {
      cleaned.add(server);
    }
  }
  settings['servers'] = cleaned;
  outbound['settings'] = Map<String, dynamic>.from(settings);
}

void _applyDecodedCredentials(Map<String, dynamic> config, String shareLink) {
  final userInfo = extractShareUserInfo(shareLink);
  if (userInfo == null || userInfo.isEmpty) return;
  final scheme = shareLink.split('://').first.toLowerCase();
  final outbounds = config['outbounds'];
  if (outbounds is! List) return;

  for (final outbound in outbounds) {
    if (outbound is! Map) continue;
    final protocol = (outbound['protocol'] as String?)?.toLowerCase();
    final settings = outbound['settings'];
    if (settings is! Map) continue;

    if (scheme == 'trojan' && protocol == 'trojan') {
      final servers = settings['servers'];
      if (servers is List && servers.isNotEmpty && servers.first is Map) {
        final server = Map<String, dynamic>.from(servers.first as Map);
        server['password'] = userInfo;
        servers[0] = server;
      }
    }

    if ((scheme == 'vless' || scheme == 'vmess') &&
        (protocol == 'vless' || protocol == 'vmess')) {
      final vnext = settings['vnext'];
      if (vnext is List && vnext.isNotEmpty && vnext.first is Map) {
        final node = Map<String, dynamic>.from(vnext.first as Map);
        final users = node['users'];
        if (users is List && users.isNotEmpty && users.first is Map) {
          final user = Map<String, dynamic>.from(users.first as Map);
          user['id'] = userInfo;
          users[0] = user;
        }
        vnext[0] = node;
      }
    }
  }
}

/// Password / UUID from a share link, percent-decoded (V2rayNG behavior).
String? extractShareUserInfo(String link) {
  final schemeIdx = link.indexOf('://');
  if (schemeIdx < 0) return null;
  var rest = link.substring(schemeIdx + 3);
  final hash = rest.indexOf('#');
  if (hash >= 0) rest = rest.substring(0, hash);
  final query = rest.indexOf('?');
  if (query >= 0) rest = rest.substring(0, query);
  final at = rest.lastIndexOf('@');
  if (at <= 0) return null;
  final raw = rest.substring(0, at);
  try {
    return Uri.decodeComponent(raw);
  } catch (_) {
    return raw;
  }
}

/// Encode characters in userinfo that Dart's URI parser mishandles (`$`, `#`).
String sanitizeShareLink(String link) {
  final schemeIdx = link.indexOf('://');
  if (schemeIdx < 0) return link;
  final start = schemeIdx + 3;
  final rest = link.substring(start);
  final at = rest.lastIndexOf('@');
  if (at <= 0) return link;
  final userInfo = rest.substring(0, at);
  if (!RegExp(r'[\$#?]').hasMatch(userInfo)) return link;
  final encoded = userInfo.replaceAllMapped(RegExp(r'[\$#?]'), (match) {
    return Uri.encodeComponent(match[0]!);
  });
  return '${link.substring(0, start)}$encoded${rest.substring(at)}';
}
