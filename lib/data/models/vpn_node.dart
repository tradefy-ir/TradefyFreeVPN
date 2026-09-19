import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/core/utils/country_names.dart';
import 'package:tradefy_vpn/core/utils/flag_emoji.dart';

class VpnNode {
  const VpnNode({
    required this.id,
    required this.shareLink,
    required this.configJson,
    required this.protocol,
    required this.address,
    required this.port,
    required this.pingMs,
    required this.countryCode,
    required this.country,
    this.indexInCountry = 1,
  });

  final String id;
  final String shareLink;
  final String configJson;
  final String protocol;
  final String address;
  final int port;
  final int pingMs;
  final String countryCode;
  final String country;
  final int indexInCountry;

  String get flag => flagEmoji(countryCode);

  String get displayName => '${AppConfig.nodeDisplayName} #$indexInCountry';

  String get pingLabel => pingMs > 0 ? '${pingMs}ms' : '—';

  String get countryTitle => '$flag ${countryNameFa(countryCode, country)}';

  VpnNode copyWith({
    int? pingMs,
    String? countryCode,
    String? country,
    int? indexInCountry,
    String? configJson,
  }) {
    return VpnNode(
      id: id,
      shareLink: shareLink,
      configJson: configJson ?? this.configJson,
      protocol: protocol,
      address: address,
      port: port,
      pingMs: pingMs ?? this.pingMs,
      countryCode: countryCode ?? this.countryCode,
      country: country ?? this.country,
      indexInCountry: indexInCountry ?? this.indexInCountry,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shareLink': shareLink,
      'configJson': configJson,
      'protocol': protocol,
      'address': address,
      'port': port,
      'pingMs': pingMs,
      'countryCode': countryCode,
      'country': country,
      'indexInCountry': indexInCountry,
    };
  }

  factory VpnNode.fromJson(Map<String, dynamic> json) {
    return VpnNode(
      id: json['id'] as String,
      shareLink: json['shareLink'] as String,
      configJson: json['configJson'] as String,
      protocol: json['protocol'] as String,
      address: json['address'] as String,
      port: json['port'] as int,
      pingMs: json['pingMs'] as int,
      countryCode: json['countryCode'] as String,
      country: json['country'] as String,
      indexInCountry: json['indexInCountry'] as int? ?? 1,
    );
  }
}
