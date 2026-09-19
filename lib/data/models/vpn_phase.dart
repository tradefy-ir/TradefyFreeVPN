enum VpnPhase {
  boot,
  fetching,
  pinging,
  locating,
  ready,
  connecting,
  connected,
  disconnecting,
  error,
}

extension VpnPhaseX on VpnPhase {
  bool get isBusy =>
      this == VpnPhase.boot ||
      this == VpnPhase.fetching ||
      this == VpnPhase.pinging ||
      this == VpnPhase.locating ||
      this == VpnPhase.connecting ||
      this == VpnPhase.disconnecting;

  String get labelFa {
    switch (this) {
      case VpnPhase.boot:
        return 'در حال آماده‌سازی هسته';
      case VpnPhase.fetching:
        return 'دریافت اشتراک‌ها';
      case VpnPhase.pinging:
        return 'بررسی پینگ واقعی';
      case VpnPhase.locating:
        return 'تشخیص لوکیشن سرورها';
      case VpnPhase.ready:
        return 'آماده اتصال';
      case VpnPhase.connecting:
        return 'در حال اتصال';
      case VpnPhase.connected:
        return 'متصل';
      case VpnPhase.disconnecting:
        return 'در حال قطع اتصال';
      case VpnPhase.error:
        return 'خطا';
    }
  }
}
