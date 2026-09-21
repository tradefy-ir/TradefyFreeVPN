import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/data/models/ad_config.dart';
import 'package:tradefy_vpn/data/models/vpn_node.dart';
import 'package:tradefy_vpn/data/models/vpn_phase.dart';
import 'package:tradefy_vpn/data/node_cache.dart';
import 'package:tradefy_vpn/data/subscription_service.dart';
import 'package:tradefy_vpn/services/ad_service.dart';
import 'package:tradefy_vpn/services/probe_service.dart';
import 'package:tradefy_vpn/services/session_service.dart';
import 'package:tradefy_vpn/services/xray_service.dart';

class VpnController extends ChangeNotifier with WidgetsBindingObserver {
  VpnController({
    XrayService? xray,
    SubscriptionService? subscriptions,
    NodeCache? cache,
    AdService? ads,
  }) : xray = xray ?? XrayService(),
       _subscriptions = subscriptions ?? SubscriptionService(),
       _cache = cache ?? NodeCache(),
       ads = ads ?? AdService() {
    probe = ProbeService(xray: this.xray);
    session = SessionService(cache: _cache);
  }

  final XrayService xray;
  final SubscriptionService _subscriptions;
  final NodeCache _cache;
  final AdService ads;
  late final ProbeService probe;
  late final SessionService session;

  VpnPhase phase = VpnPhase.boot;
  String? errorMessage;
  String loadingDetail = '';
  List<VpnNode> nodes = <VpnNode>[];
  VpnNode? selected;
  bool sessionExpired = false;
  int pingDone = 0;
  int pingTotal = 0;
  bool backgroundRefresh = false;

  V2RayStatus get runtimeStatus => xray.status;
  AdConfig get adConfig => ads.current;
  bool get isConnected =>
      _userWantsConnection && xray.isConnected && phase == VpnPhase.connected;

  List<VpnNode> get visibleNodes {
    final list = [...nodes]..sort((a, b) {
      final aPing = a.pingMs > 0 ? a.pingMs : 1 << 30;
      final bPing = b.pingMs > 0 ? b.pingMs : 1 << 30;
      final ping = aPing.compareTo(bPing);
      if (ping != 0) return ping;
      return a.indexInCountry.compareTo(b.indexInCountry);
    });
    return list;
  }

  Timer? _sessionTicker;
  Timer? _refreshTimer;
  bool _started = false;
  bool _refreshing = false;
  bool _pinging = false;
  bool _userWantsConnection = false;

  bool get showAsConnected =>
      _userWantsConnection && phase == VpnPhase.connected;

  bool get isPinging => _pinging;
  bool get listBusy => _refreshing || _pinging;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    xray.statusListenable.addListener(_onRuntimeStatus);
    session.setNotificationDisconnectHandler(() => disconnect());
    await xray.initialize();
    await session.restore();
    if (await session.consumePendingDisconnect()) {
      await disconnect();
    }
    await ads.load();
    await _enforceExpiredSession();
    await refreshServers(force: true);
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      AppConfig.subscriptionRefreshInterval,
      (_) => refreshServers(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResume());
    }
  }

  Future<void> _onResume() async {
    await _enforceExpiredSession();
    final last = await _cache.lastRefresh();
    if (last == null ||
        DateTime.now().difference(last) >= AppConfig.subscriptionRefreshInterval) {
      await refreshServers();
    }
  }

  Future<void> refreshServers({bool force = false}) async {
    if (_refreshing || _pinging) return;
    _refreshing = true;

    final keepConnection = _userWantsConnection &&
        (isConnected || phase == VpnPhase.connected);
    final previousSelectedId = selected?.id ?? await _cache.loadSelectedId();
    errorMessage = null;
    sessionExpired = keepConnection ? sessionExpired : false;
    pingDone = 0;
    pingTotal = 0;
    backgroundRefresh = keepConnection || nodes.isNotEmpty;
    if (!backgroundRefresh) {
      phase = VpnPhase.fetching;
      loadingDetail = 'در حال دریافت لینک‌های اشتراک';
      notifyListeners();
    } else {
      loadingDetail = 'به‌روزرسانی لیست سرورها';
      notifyListeners();
    }

    try {
      final parsed = await _subscriptions.fetchNodes();
      if (parsed.isEmpty) {
        final cached = await _cache.loadNodes();
        if (cached.isEmpty) {
          throw Exception('هیچ کانفیگ معتبری از اشتراک‌ها دریافت نشد');
        }
        nodes = cached;
        _restoreSelection(previousSelectedId);
        backgroundRefresh = false;
        phase = keepConnection ? VpnPhase.connected : VpnPhase.ready;
        notifyListeners();
        return;
      }

      final previousById = {for (final node in nodes) node.id: node};
      final merged = [
        for (final node in parsed)
          _mergeCachedProbe(node, previousById[node.id]),
      ];

      final probed = probe.numberNodes(merged);
      nodes = probed;
      await _cache.saveNodes(nodes);
      _restoreSelection(previousSelectedId);
      backgroundRefresh = false;
      phase = keepConnection ? VpnPhase.connected : VpnPhase.ready;
      loadingDetail = '';
      notifyListeners();
    } catch (error) {
      final cached = await _cache.loadNodes();
      if (cached.isNotEmpty) {
        nodes = cached;
        _restoreSelection(previousSelectedId);
        backgroundRefresh = false;
        phase = keepConnection ? VpnPhase.connected : VpnPhase.ready;
        errorMessage = 'به‌روزرسانی ناموفق بود؛ لیست قبلی نمایش داده شد';
      } else {
        backgroundRefresh = false;
        phase = VpnPhase.error;
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      }
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> testPing() async {
    if (_pinging || _refreshing || showAsConnected || nodes.isEmpty) return;
    _pinging = true;
    final previousSelectedId = selected?.id;
    errorMessage = null;
    phase = VpnPhase.pinging;
    pingDone = 0;
    pingTotal = nodes.length;
    loadingDetail = 'پینگ ۰ از $pingTotal';
    notifyListeners();

    try {
      final alive = await probe.keepReachable(
        nodes,
        onProgress: (done, total, detail) {
          pingDone = done;
          pingTotal = total;
          loadingDetail = detail;
          notifyListeners();
        },
      );

      if (alive.isEmpty) {
        errorMessage = 'هیچ سروری پینگ واقعی نداشت؛ لیست بدون تغییر ماند';
        phase = VpnPhase.ready;
        loadingDetail = '';
        notifyListeners();
        return;
      }

      nodes = alive;
      await _cache.saveNodes(nodes);
      _restoreSelection(previousSelectedId);
      phase = VpnPhase.ready;
      loadingDetail = '';
      notifyListeners();
    } catch (_) {
      phase = VpnPhase.ready;
      errorMessage = 'تست پینگ ناموفق بود';
      loadingDetail = '';
      notifyListeners();
    } finally {
      _pinging = false;
      notifyListeners();
    }
  }

  VpnNode _mergeCachedProbe(VpnNode fresh, VpnNode? old) {
    if (old == null) return fresh;
    return fresh.copyWith(
      pingMs: old.pingMs,
      countryCode: old.countryCode,
      country: old.country,
      indexInCountry: old.indexInCountry,
    );
  }

  void _restoreSelection(String? id) {
    if (nodes.isEmpty) {
      selected = null;
      return;
    }
    selected = nodes.where((node) => node.id == id).firstOrNull ?? nodes.first;
  }

  void selectNode(VpnNode node) {
    if (showAsConnected) return;
    selected = node;
    unawaited(_cache.saveSelectedId(node.id));
    notifyListeners();
  }

  Future<bool> connectSelected() async {
    if (showAsConnected) return false;
    if (_pinging || _refreshing) {
      errorMessage = 'صبر کنید تا به‌روزرسانی یا تست پینگ تمام شود';
      notifyListeners();
      return false;
    }
    final node = selected;
    if (node == null) {
      errorMessage = 'ابتدا یک سرور را انتخاب کنید';
      notifyListeners();
      return false;
    }
    if (sessionExpired) {
      sessionExpired = false;
    }

    _userWantsConnection = true;
    phase = VpnPhase.connecting;
    errorMessage = null;
    notifyListeners();

    try {
      final allowed = await xray.requestPermission();
      if (!allowed) {
        _userWantsConnection = false;
        phase = VpnPhase.ready;
        errorMessage = 'مجوز VPN داده نشد';
        notifyListeners();
        return false;
      }
      final tunUp = await xray.start(
        remark: node.displayName,
        configJson: node.configJson,
      );
      if (!tunUp && !xray.isConnected) {
        await xray.stop();
        _userWantsConnection = false;
        phase = VpnPhase.ready;
        errorMessage =
            'تونل سیستم برقرار نشد. مجوز VPN را تأیید کنید و دوباره وصل شوید.';
        notifyListeners();
        return false;
      }
      await session.start();
      _startSessionTicker();
      phase = VpnPhase.connected;
      notifyListeners();
      return true;
    } catch (error) {
      _userWantsConnection = false;
      phase = VpnPhase.ready;
      errorMessage = 'اتصال برقرار نشد';
      notifyListeners();
      return false;
    }
  }

  bool _disconnecting = false;

  Future<void> disconnect({bool expired = false}) async {
    if (_disconnecting && phase != VpnPhase.connected) return;
    _disconnecting = true;
    _userWantsConnection = false;
    phase = VpnPhase.disconnecting;
    notifyListeners();
    try {
      await xray.stop();
    } catch (_) {}
    await session.clear();
    _sessionTicker?.cancel();
    sessionExpired = expired;
    phase = VpnPhase.ready;
    if (expired) {
      await session.notifyExpired();
    }
    _disconnecting = false;
    notifyListeners();
  }

  void _startSessionTicker() {
    _sessionTicker?.cancel();
    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (session.isExpired) {
        unawaited(disconnect(expired: true));
        return;
      }
      if (showAsConnected) {
        notifyListeners();
      }
    });
  }

  Future<void> _enforceExpiredSession() async {
    if (session.startedAt == null) return;
    if (session.isExpired) {
      await disconnect(expired: true);
      return;
    }
    _userWantsConnection = true;
    _startSessionTicker();
    if (xray.isConnected) {
      phase = VpnPhase.connected;
    }
  }

  void _onRuntimeStatus() {
    final state = xray.status.state.toUpperCase();
    if (!_userWantsConnection) {
      if (phase == VpnPhase.connected) {
        phase = VpnPhase.ready;
        notifyListeners();
      }
      return;
    }
    if (state == 'CONNECTED') {
      if (phase != VpnPhase.connected) {
        phase = VpnPhase.connected;
        notifyListeners();
      }
      return;
    }
    if (state == 'DISCONNECTED' && phase == VpnPhase.connected) {
      final expired = session.isExpired ||
          session.remaining <= const Duration(seconds: 2);
      unawaited(disconnect(expired: expired));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    xray.statusListenable.removeListener(_onRuntimeStatus);
    _sessionTicker?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
