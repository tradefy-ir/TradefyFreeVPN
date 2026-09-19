import 'package:flutter/material.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';

/// Launcher-style rounded logo. Android already masks the app icon;
/// in-app uses must clip the same way so corners are never sharp.
class AppLogoImage extends StatelessWidget {
  const AppLogoImage({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        AppConfig.assetLogo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
