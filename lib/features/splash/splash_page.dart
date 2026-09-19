import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/core/theme/app_theme.dart';
import 'package:tradefy_vpn/data/models/vpn_phase.dart';
import 'package:tradefy_vpn/state/vpn_controller.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.showProgress = true});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VpnController>();
    final progress = _progressFor(controller);

    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppConfig.assetStart,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          if (showProgress)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress == 0 ? null : progress,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.loadingDetail.isEmpty
                            ? controller.phase.labelFa
                            : controller.loadingDetail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (controller.phase == VpnPhase.error) ...[
                        const SizedBox(height: 14),
                        Text(
                          controller.errorMessage ?? 'خطای ناشناخته',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => controller.refreshServers(force: true),
                          child: const Text('تلاش دوباره'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _progressFor(VpnController controller) {
    switch (controller.phase) {
      case VpnPhase.boot:
        return 0.08;
      case VpnPhase.fetching:
        return 0.25;
      case VpnPhase.pinging:
        if (controller.pingTotal == 0) return 0.45;
        return 0.45 + (0.4 * (controller.pingDone / controller.pingTotal));
      case VpnPhase.locating:
        return 0.92;
      case VpnPhase.error:
        return 1;
      default:
        return 1;
    }
  }
}
