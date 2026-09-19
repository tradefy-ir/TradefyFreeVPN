import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/core/theme/app_theme.dart';
import 'package:tradefy_vpn/data/models/vpn_phase.dart';
import 'package:tradefy_vpn/features/ad/ad_gate_page.dart';
import 'package:tradefy_vpn/features/home/widgets/connect_button.dart';
import 'package:tradefy_vpn/features/home/widgets/server_list.dart';
import 'package:tradefy_vpn/features/home/widgets/status_header.dart';
import 'package:tradefy_vpn/features/widgets/app_logo_image.dart';
import 'package:tradefy_vpn/services/session_service.dart';
import 'package:tradefy_vpn/state/vpn_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VpnController>();
    final connected = controller.showAsConnected;
    final remaining = controller.session.remaining;
    final status = controller.runtimeStatus;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogoImage(size: 28),
            const SizedBox(width: 8),
            const Text(AppConfig.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تست پینگ',
            onPressed: controller.listBusy || connected
                ? null
                : () => controller.testPing(),
            icon: controller.isPinging
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check_rounded),
          ),
          IconButton(
            tooltip: 'به‌روزرسانی لیست',
            onPressed: controller.listBusy
                ? null
                : () => controller.refreshServers(force: true),
            icon: controller.backgroundRefresh && !controller.isPinging
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            StatusHeader(
              phase: controller.phase,
              connected: connected,
              downloadSpeed: status.downloadSpeed,
              uploadSpeed: status.uploadSpeed,
              detail: controller.listBusy ? controller.loadingDetail : null,
            ),
            const SizedBox(height: 8),
            ConnectButton(
              connected: connected,
              busy:
                  controller.listBusy ||
                  controller.phase == VpnPhase.connecting ||
                  controller.phase == VpnPhase.disconnecting,
              remainingLabel: connected && controller.session.startedAt != null
                  ? SessionService.format(remaining)
                  : null,
              onPressed: () => _onPowerTap(context, controller),
            ),
            const SizedBox(height: 8),
            if (controller.selected != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SelectedCard(
                  title: controller.selected!.displayName,
                  pingLabel: controller.selected!.pingLabel,
                ),
              ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: controller.sessionExpired
                        ? AppTheme.warning
                        : AppTheme.danger,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Expanded(child: ServerList()),
          ],
        ),
      ),
    );
  }

  Future<void> _onPowerTap(BuildContext context, VpnController controller) async {
    if (controller.showAsConnected) {
      await controller.disconnect();
      return;
    }
    if (controller.listBusy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صبر کنید تا به‌روزرسانی یا تست پینگ تمام شود')),
      );
      return;
    }
    if (controller.selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا یک سرور را انتخاب کنید')),
      );
      return;
    }

    final watched = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const AdGatePage(),
      ),
    );
    if (watched != true || !context.mounted) return;
    await controller.connectSelected();
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({
    required this.title,
    required this.pingLabel,
  });

  final String title;
  final String pingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(
            pingLabel,
            style: TextStyle(
              color: pingLabel == '—' ? AppTheme.textSecondary : AppTheme.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
