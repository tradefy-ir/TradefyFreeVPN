import 'package:flutter/material.dart';
import 'package:tradefy_vpn/core/theme/app_theme.dart';
import 'package:tradefy_vpn/data/models/vpn_phase.dart';

class StatusHeader extends StatelessWidget {
  const StatusHeader({
    super.key,
    required this.phase,
    required this.connected,
    required this.downloadSpeed,
    required this.uploadSpeed,
    this.detail,
  });

  final VpnPhase phase;
  final bool connected;
  final int downloadSpeed;
  final int uploadSpeed;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppTheme.accent : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Text(
            phase.labelFa,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 6),
          if (connected)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SpeedChip(icon: Icons.arrow_downward_rounded, value: downloadSpeed),
                const SizedBox(width: 16),
                _SpeedChip(icon: Icons.arrow_upward_rounded, value: uploadSpeed),
              ],
            ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          _formatBytes(value),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B/s';
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit += 1;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unit]}';
  }
}
