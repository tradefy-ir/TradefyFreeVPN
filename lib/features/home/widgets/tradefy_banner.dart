import 'package:flutter/material.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class TradefyBanner extends StatelessWidget {
  const TradefyBanner({super.key});

  Future<void> _openSite() async {
    final uri = Uri.parse(AppConfig.websiteUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openSite,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Image.asset(
              AppConfig.assetBanner,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
