import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tradefy_vpn/core/utils/proxy_host.dart';

class GeoResult {
  const GeoResult({required this.countryCode, required this.country});

  final String countryCode;
  final String country;
}

class GeoService {
  GeoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, GeoResult> _cache = <String, GeoResult>{};

  Future<GeoResult> lookup(String host) async {
    final key = host.trim().toLowerCase();
    if (key.isEmpty || isCamouflageHost(key)) {
      return const GeoResult(countryCode: 'UN', country: 'Unknown');
    }
    final cached = _cache[key];
    if (cached != null) return cached;

    final result = await _lookupIpApi(key) ?? await _lookupIpWho(key);
    final resolved =
        result ?? const GeoResult(countryCode: 'UN', country: 'Unknown');
    _cache[key] = resolved;
    return resolved;
  }

  Future<GeoResult?> _lookupIpApi(String host) async {
    try {
      final uri = Uri.parse(
        'http://ip-api.com/json/${Uri.encodeComponent(host)}?fields=status,country,countryCode,message',
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      return geoResultFromIpApi(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  Future<GeoResult?> _lookupIpWho(String host) async {
    try {
      final uri = Uri.parse('https://ipwho.is/${Uri.encodeComponent(host)}');
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;
      if (json['success'] == false) return null;
      final code = (json['country_code'] as String? ?? '').toUpperCase();
      final country = json['country'] as String? ?? code;
      if (code.isEmpty) return null;
      return GeoResult(countryCode: code, country: country);
    } catch (_) {
      return null;
    }
  }
}

GeoResult? geoResultFromIpApi(Object? decoded) {
  if (decoded is! Map) return null;
  final json = Map<String, dynamic>.from(decoded);
  if (json['status'] != 'success') return null;
  final code = (json['countryCode'] as String? ?? '').toUpperCase();
  final country = json['country'] as String? ?? code;
  if (code.isEmpty) return null;
  return GeoResult(countryCode: code, country: country);
}
