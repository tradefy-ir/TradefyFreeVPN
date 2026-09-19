import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/data/models/ad_config.dart';

class AdService {
  AdService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  AdConfig _cached = AdConfig.fallback();

  AdConfig get current => _cached;

  Future<AdConfig> load() async {
    try {
      final response = await _client
          .get(Uri.parse(AppConfig.adConfigUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          _cached = AdConfig.fromJson(decoded);
          return _cached;
        }
      }
    } catch (_) {}
    return _cached;
  }
}
