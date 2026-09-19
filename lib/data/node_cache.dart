import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradefy_vpn/data/models/vpn_node.dart';

class NodeCache {
  static const _nodesKey = 'cached_nodes_v1';
  static const _refreshKey = 'last_refresh_ms';
  static const _sessionStartKey = 'session_start_ms';
  static const _selectedIdKey = 'selected_node_id';

  Future<void> saveNodes(List<VpnNode> nodes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(nodes.map((node) => node.toJson()).toList());
    await prefs.setString(_nodesKey, encoded);
    await prefs.setInt(_refreshKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<VpnNode>> loadNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_nodesKey);
    if (raw == null || raw.isEmpty) return <VpnNode>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <VpnNode>[];
      return decoded
          .whereType<Map>()
          .map((item) => VpnNode.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return <VpnNode>[];
    }
  }

  Future<DateTime?> lastRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_refreshKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveSelectedId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_selectedIdKey);
    } else {
      await prefs.setString(_selectedIdKey, id);
    }
  }

  Future<String?> loadSelectedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedIdKey);
  }

  Future<void> saveSessionStart(DateTime? start) async {
    final prefs = await SharedPreferences.getInstance();
    if (start == null) {
      await prefs.remove(_sessionStartKey);
    } else {
      await prefs.setInt(_sessionStartKey, start.millisecondsSinceEpoch);
    }
  }

  Future<DateTime?> loadSessionStart() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_sessionStartKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
