import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tradefy_vpn/core/theme/app_theme.dart';
import 'package:tradefy_vpn/data/models/vpn_node.dart';
import 'package:tradefy_vpn/state/vpn_controller.dart';

class ServerList extends StatelessWidget {
  const ServerList({super.key});

  @override
  Widget build(BuildContext context) {
    final nodes = context.select<VpnController, List<VpnNode>>((c) => c.nodes);
    final selectedId = context.select<VpnController, String?>(
      (c) => c.selected?.id,
    );
    final connected = context.select<VpnController, bool>(
      (c) => c.showAsConnected,
    );
    final controller = context.read<VpnController>();
    final visible = [...nodes]..sort((a, b) {
      final aPing = a.pingMs > 0 ? a.pingMs : 1 << 30;
      final bPing = b.pingMs > 0 ? b.pingMs : 1 << 30;
      final ping = aPing.compareTo(bPing);
      if (ping != 0) return ping;
      return a.indexInCountry.compareTo(b.indexInCountry);
    });

    if (visible.isEmpty) {
      return const Center(child: Text('سروری برای نمایش نیست'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final node = visible[index];
        return _NodeTile(
          node: node,
          selected: node.id == selectedId,
          enabled: !connected,
          onTap: () => controller.selectNode(node),
        );
      },
    );
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final VpnNode node;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.card : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.protocol.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                node.pingLabel,
                style: TextStyle(
                  color: node.pingMs <= 0
                      ? AppTheme.textSecondary
                      : node.pingMs < 400
                          ? AppTheme.accent
                          : AppTheme.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.accent,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
