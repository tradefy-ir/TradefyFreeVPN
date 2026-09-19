import 'package:tradefy_vpn/core/config/app_config.dart';

enum AdMediaType { image, video }

class AdConfig {
  const AdConfig({
    required this.type,
    required this.url,
    required this.duration,
  });

  final AdMediaType type;
  final String? url;
  final Duration duration;

  bool get hasRemoteMedia => url != null && url!.trim().isNotEmpty;

  factory AdConfig.fallback() {
    return const AdConfig(
      type: AdMediaType.image,
      url: null,
      duration: AppConfig.adDuration,
    );
  }

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] as String? ?? 'image').toLowerCase();
    final seconds = json['durationSeconds'];
    return AdConfig(
      type: typeRaw == 'video' ? AdMediaType.video : AdMediaType.image,
      url: json['url'] as String?,
      duration: seconds is num
          ? Duration(seconds: seconds.toInt())
          : AppConfig.adDuration,
    );
  }
}
