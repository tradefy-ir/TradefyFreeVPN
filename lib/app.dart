import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/core/theme/app_theme.dart';
import 'package:tradefy_vpn/features/home/home_page.dart';
import 'package:tradefy_vpn/features/splash/splash_page.dart';
import 'package:tradefy_vpn/state/vpn_controller.dart';

class TradefyApp extends StatefulWidget {
  const TradefyApp({super.key});

  @override
  State<TradefyApp> createState() => _TradefyAppState();
}

class _TradefyAppState extends State<TradefyApp> {
  late final VpnController _controller;
  bool _brandSplashDone = false;

  @override
  void initState() {
    super.initState();
    _controller = VpnController()..start();
    Future<void>.delayed(AppConfig.brandSplashDuration, () {
      if (!mounted) return;
      setState(() => _brandSplashDone = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VpnController>.value(
      value: _controller,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Consumer<VpnController>(
          builder: (context, controller, _) {
            if (!_brandSplashDone || controller.nodes.isEmpty) {
              return SplashPage(showProgress: _brandSplashDone);
            }
            return const HomePage();
          },
        ),
      ),
    );
  }
}
