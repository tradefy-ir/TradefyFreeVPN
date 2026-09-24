class AppConfig {
  AppConfig._();

  static const String appName = 'TradefyVPN';
  static const String nodeDisplayName = 'TradefyVPN';
  static const String specialNodeDisplayName = 'TradefyVpn';
  static const String specialServersTitle = 'Special Servers';

  /// Fixed Xray subscription URLs. Add more entries here as needed.
  static const List<String> subscriptionUrls = [
    'https://dy6n8l2pey3lkuv1w4.chavoshfx.workers.dev/wF74and2hJ_06/sub/raw?app=xray',
    'https://i294pozd48ks9uci6677m2ju9evv.6uhtrkoq2jsohrw8v6n0emmoq1tf30.workers.dev/LjTgo4B5g_BR/sub/raw?app=xray',
  ];

  static const String specialSubscriptionUrl =
      'https://proxy-production-7498.up.railway.app/sub/djMsMiwxNzkwMjAzMjYx.R10Ou51jzF7vC6FomzIXniTCF3O_m7IvnjwXYGMXpWA';

  static const String adConfigUrl = 'https://tradefy.ir/vpn-ad.json';
  static const Duration adDuration = Duration(seconds: 15);
  static const Duration sessionLimit = Duration(hours: 1);
  static const Duration subscriptionRefreshInterval = Duration(hours: 1);
  static const Duration pingTimeout = Duration(seconds: 12);
  static const Duration tcpProbeTimeout = Duration(seconds: 1);
  static const int pingConcurrency = 16;
  static const int delayFailureMs = -1;

  static const String delayTestUrl = 'https://www.gstatic.com/generate_204';
  static const String userAgent = 'v2rayNG/1.10.11';
  static const String websiteUrl = 'https://www.tradefy.ir/fa';
  static const Duration brandSplashDuration = Duration(seconds: 2);

  static const String assetStart = 'images/startApp.png';
  static const String assetLogo = 'images/AppLogo.png';
  static const String assetBanner = 'images/banner.png';
}
