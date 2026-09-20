import 'package:flutter/services.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/data/node_cache.dart';

class SessionService {
  SessionService({required this._cache});

  final NodeCache _cache;
  static const _channel = MethodChannel('com.tradefy.tradefy_vpn/session');

  DateTime? _startedAt;

  DateTime? get startedAt => _startedAt;

  Duration get remaining {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    final elapsed = DateTime.now().difference(start);
    final left = AppConfig.sessionLimit - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isExpired => _startedAt != null && remaining == Duration.zero;

  void setNotificationDisconnectHandler(Future<void> Function() handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationDisconnect') {
        await handler();
      }
    });
  }

  Future<bool> consumePendingDisconnect() async {
    try {
      final pending = await _channel.invokeMethod<bool>('consumePendingDisconnect');
      return pending ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> restore() async {
    _startedAt = await _cache.loadSessionStart();
  }

    Future<void> start() async {
    _startedAt = DateTime.now();
    await _cache.saveSessionStart(_startedAt);
    try {
      await _channel.invokeMethod<void>('cancelSessionExpiredNotification');
    } catch (_) {}
    try {
      await _channel.invokeMethod<void>('scheduleTimeout', <String, int>{
        'millis': AppConfig.sessionLimit.inMilliseconds,
      });
    } catch (_) {}
  }

  Future<void> notifyExpired() async {
    try {
      await _channel.invokeMethod<void>('showSessionExpiredNotification');
    } catch (_) {}
  }

  Future<void> clear() async {
    _startedAt = null;
    await _cache.saveSessionStart(null);
    try {
      await _channel.invokeMethod<void>('cancelTimeout');
    } catch (_) {}
  }

  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
