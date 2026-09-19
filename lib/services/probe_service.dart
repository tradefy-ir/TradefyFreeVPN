import 'dart:io';

import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/core/utils/async_pool.dart';
import 'package:tradefy_vpn/data/models/vpn_node.dart';
import 'package:tradefy_vpn/services/xray_service.dart';

class ProbeService {
  ProbeService({required XrayService xray}) : _xray = xray;

  final XrayService _xray;

  Future<List<VpnNode>> keepReachable(
    List<VpnNode> nodes, {
    void Function(int done, int total, String detail)? onProgress,
  }) async {
    if (nodes.isEmpty) return const <VpnNode>[];

    onProgress?.call(0, nodes.length, 'اسکن موازی پورت‌ها');
    final reachable = await Future.wait([
      for (final node in nodes) _tcpAlive(node),
    ]);
    final candidates = [
      for (var i = 0; i < nodes.length; i++)
        if (reachable[i]) nodes[i],
    ];

    final toPing = candidates.isEmpty ? nodes : candidates;
    var completed = 0;
    final pinged = await mapLimited(toPing, AppConfig.pingConcurrency, (
      node,
    ) async {
      final delay = await _xray.measureDelay(node.configJson);
      completed += 1;
      onProgress?.call(
        completed,
        toPing.length,
        'پینگ واقعی $completed از ${toPing.length}',
      );
      if (delay <= 0) return null;
      return node.copyWith(pingMs: delay);
    });
    return numberNodes(pinged.whereType<VpnNode>().toList());
  }

  List<VpnNode> numberNodes(List<VpnNode> nodes) {
    final sorted = [...nodes]..sort((a, b) {
      final aPing = a.pingMs > 0 ? a.pingMs : 1 << 30;
      final bPing = b.pingMs > 0 ? b.pingMs : 1 << 30;
      final ping = aPing.compareTo(bPing);
      if (ping != 0) return ping;
      return a.address.compareTo(b.address);
    });
    return [
      for (var i = 0; i < sorted.length; i++)
        sorted[i].copyWith(indexInCountry: i + 1),
    ];
  }

  Future<bool> _tcpAlive(VpnNode node) async {
    try {
      final socket = await Socket.connect(
        node.address,
        node.port,
        timeout: AppConfig.tcpProbeTimeout,
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
