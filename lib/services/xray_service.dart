import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/core/utils/xray_config.dart';

class XrayService {
  XrayService() {
    _client = V2ray(
      onStatusChanged: (status) {
        if (_ignoreStatusUpdates) return;
        _status = status;
        statusListenable.value = status;
      },
    );
  }

  late final V2ray _client;
  V2RayStatus _status = V2RayStatus();
  bool _initialized = false;
  bool _ignoreStatusUpdates = false;
  int _inflightDelays = 0;
  Completer<void>? _delaysIdle;

  final ValueNotifier<V2RayStatus> statusListenable = ValueNotifier<V2RayStatus>(
    V2RayStatus(),
  );

  V2RayStatus get status => _status;

  bool get isConnected => _status.state.toUpperCase() == 'CONNECTED';

  Future<void> initialize() async {
    if (_initialized) return;
    await _client.initialize(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
    _initialized = true;
  }

  /// Same model as V2rayNG: each call creates its own temporary Xray
  /// instance, so several tests can run at once.
  Future<int> measureDelay(String configJson) async {
    _beginDelay();
    try {
      final delay = await _client
          .getServerDelay(config: configJson, url: AppConfig.delayTestUrl)
          .timeout(AppConfig.pingTimeout);
      return delay > 0 ? delay : AppConfig.delayFailureMs;
    } catch (_) {
      return AppConfig.delayFailureMs;
    } finally {
      _endDelay();
    }
  }

  void _beginDelay() {
    _inflightDelays += 1;
  }

  void _endDelay() {
    _inflightDelays -= 1;
    if (_inflightDelays > 0) return;
    _inflightDelays = 0;
    final idle = _delaysIdle;
    _delaysIdle = null;
    if (idle != null && !idle.isCompleted) {
      idle.complete();
    }
  }

  Future<void> _waitForIdleDelays() async {
    if (_inflightDelays <= 0) return;
    _delaysIdle ??= Completer<void>();
    await _delaysIdle!.future;
  }

  Future<bool> requestPermission() {
    return _client.requestPermission();
  }

  Future<void> start({
    required String remark,
    required String configJson,
  }) async {
    await _waitForIdleDelays();
    _ignoreStatusUpdates = false;
    try {
      await _client.stopV2Ray();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _client.startV2Ray(
      remark: remark,
      config: applyVpnRuntimeSettings(configJson),
      blockedApps: null,
      bypassSubnets: null,
      proxyOnly: false,
      notificationDisconnectButtonName: 'قطع اتصال',
    );
  }

  Future<bool> waitUntilConnected({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (isConnected) return true;
    final completer = Completer<bool>();
    void listener() {
      if (isConnected && !completer.isCompleted) {
        completer.complete(true);
      }
    }

    statusListenable.addListener(listener);
    try {
      return await Future.any<bool>([
        completer.future,
        Future<bool>.delayed(timeout, () => isConnected),
      ]);
    } finally {
      statusListenable.removeListener(listener);
    }
  }

  Future<void> stop() async {
    _ignoreStatusUpdates = true;
    try {
      await _client.stopV2Ray();
    } finally {
      _status = V2RayStatus();
      statusListenable.value = _status;
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        _ignoreStatusUpdates = false;
      });
    }
  }
}
