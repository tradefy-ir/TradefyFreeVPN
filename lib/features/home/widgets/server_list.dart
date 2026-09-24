import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
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
    final special = [
      ...nodes.where((node) => node.isSpecial),
    ]..sort(_byPing);
    final regular = [
      ...nodes.where((node) => !node.isSpecial),
    ]..sort(_byPing);

    if (special.isEmpty && regular.isEmpty) {
      return const Center(child: Text('سروری برای نمایش نیست'));
    }

    return CustomScrollView(
      slivers: [
        if (special.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SectionTitle(AppConfig.specialServersTitle),
            ),
          ),
          _nodeSliver(special, selectedId, connected, controller),
        ],
        if (special.isNotEmpty && regular.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (regular.isNotEmpty) ...[
          if (special.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _SectionTitle('سرورها'),
              ),
            ),
          _nodeSliver(regular, selectedId, connected, controller),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  static SliverPadding _nodeSliver(
    List<VpnNode> nodes,
    String? selectedId,
    bool connected,
    VpnController controller,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: nodes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final node = nodes[index];
          return _NodeTile(
            node: node,
            selected: node.id == selectedId,
            enabled: !connected,
            onTap: () => controller.selectNode(node),
          );
        },
      ),
    );
  }

  static int _byPing(VpnNode a, VpnNode b) {
    final aPing = a.pingMs > 0 ? a.pingMs : 1 << 30;
    final bPing = b.pingMs > 0 ? b.pingMs : 1 << 30;
    final ping = aPing.compareTo(bPing);
    if (ping != 0) return ping;
    return a.indexInCountry.compareTo(b.indexInCountry);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.accent,
        fontWeight: FontWeight.w800,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
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
