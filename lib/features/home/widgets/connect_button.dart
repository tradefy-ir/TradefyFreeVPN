import 'package:flutter/material.dart';
import 'package:tradefy_vpn/core/theme/app_theme.dart';

class ConnectButton extends StatelessWidget {
  const ConnectButton({
    super.key,
    required this.connected,
    required this.busy,
    required this.onPressed,
    this.remainingLabel,
  });

  final bool connected;
  final bool busy;
  final VoidCallback onPressed;
  final String? remainingLabel;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppTheme.accent : const Color(0xFF4B5E78);
    return Column(
      children: [
        GestureDetector(
          onTap: busy ? null : onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.55),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: connected ? 0.45 : 0.18),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    connected ? Icons.power_settings_new_rounded : Icons.power_settings_new,
                    size: 58,
                    color: Colors.white,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          connected ? 'برای قطع، لمس کنید' : 'برای اتصال، لمس کنید',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        if (remainingLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            'زمان باقی‌مانده $remainingLabel',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
