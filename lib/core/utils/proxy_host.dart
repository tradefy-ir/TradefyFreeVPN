import 'dart:convert';

/// CDN / camouflage destinations that are not the VPN exit country.
bool isCamouflageHost(String host) {
  final value = host.trim().toLowerCase();
  if (value.isEmpty) return true;
  if (value.endsWith('.workers.dev') ||
      value.endsWith('.pages.dev') ||
      value.contains('cloudflare') ||
      value.contains('speedtest') ||
      value == 'cloudflare.com' ||
      value == 'www.cloudflare.com') {
    return true;
  }
  return _isCloudflareIpv4(value);
}

bool _isCloudflareIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  final octets = <int>[];
  for (final part in parts) {
    final n = int.tryParse(part);
    if (n == null || n < 0 || n > 255) return false;
    octets.add(n);
  }
  final a = octets[0];
  final b = octets[1];
  if (a == 104 && b >= 16 && b <= 31) return true;
  if (a == 172 && b >= 64 && b <= 71) return true;
  if (a == 162 && (b == 158 || b == 159)) return true;
  if (a == 188 && b == 114) return true;
  if (a == 190 && b == 93) return true;
  if (a == 197 && b == 234) return true;
  if (a == 141 && b == 101) return true;
  if (a == 173 && b == 245) return true;
  if (a == 198 && b == 41) return true;
  return false;
}

/// Host suitable for a cheap (non-proxy) geo lookup. Skips Cloudflare fronts.
String? extractPreferredHost(String configJson) {
  for (final host in _configHosts(configJson)) {
    if (!isCamouflageHost(host)) return host;
  }
  return null;
}

/// Stable key so VLESS/Trojan/Clean-IP variants of one panel share one exit probe.
String backendIdentity(String configJson, String shareLink) {
  final hosts = _configHosts(configJson);
  final sni = hosts.isEmpty ? '' : hosts.first;
  if (sni.isNotEmpty) return 'sni|$sni';
  return 'link|$shareLink';
}

List<String> _configHosts(String configJson) {
  try {
    final decoded = jsonDecode(configJson);
    if (decoded is! Map) return const <String>[];
    final outbounds = decoded['outbounds'];
    if (outbounds is! List) return const <String>[];
    Map<String, dynamic>? proxy;
    for (final item in outbounds) {
      if (item is! Map) continue;
      final protocol = item['protocol'];
      if (protocol == 'freedom' || protocol == 'blackhole' || protocol == 'tun') {
        continue;
      }
      proxy = Map<String, dynamic>.from(item);
      break;
    }
    if (proxy == null) return const <String>[];

    final hosts = <String>[];
    final stream = proxy['streamSettings'];
    if (stream is Map) {
      final tls = stream['tlsSettings'];
      if (tls is Map) {
        _addHost(hosts, tls['serverName']);
      }
      final reality = stream['realitySettings'];
      if (reality is Map) {
        _addHost(hosts, reality['serverName']);
      }
      final ws = stream['wsSettings'];
      if (ws is Map) {
        _addHost(hosts, ws['host']);
        final headers = ws['headers'];
        if (headers is Map) {
          _addHost(hosts, headers['Host'] ?? headers['host']);
        }
      }
    }

    final settings = proxy['settings'];
    if (settings is Map) {
      final vnext = settings['vnext'];
      if (vnext is List && vnext.isNotEmpty && vnext.first is Map) {
        _addHost(hosts, (vnext.first as Map)['address']);
      }
      final servers = settings['servers'];
      if (servers is List && servers.isNotEmpty && servers.first is Map) {
        _addHost(hosts, (servers.first as Map)['address']);
      }
    }
    return hosts;
  } catch (_) {
    return const <String>[];
  }
}

void _addHost(List<String> hosts, Object? value) {
  if (value is! String) return;
  final host = value.trim();
  if (host.isEmpty) return;
  if (!hosts.contains(host)) hosts.add(host);
}
