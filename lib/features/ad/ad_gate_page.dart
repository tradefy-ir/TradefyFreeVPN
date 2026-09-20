import 'package:flutter/material.dart';
import 'package:tradefy_vpn/core/config/app_config.dart';
import 'package:tradefy_vpn/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AdGatePage extends StatefulWidget {
  const AdGatePage({super.key, this.duration = AppConfig.adDuration});

  final Duration duration;

  @override
  State<AdGatePage> createState() => _AdGatePageState();
}

class _AdGatePageState extends State<AdGatePage> with WidgetsBindingObserver {
  late int _secondsLeft;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsLeft = widget.duration.inSeconds;
    _tick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _cancelWatch();
    }
  }

  Future<void> _tick() async {
    while (mounted && !_finished && _secondsLeft > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || _finished) return;
      setState(() => _secondsLeft -= 1);
    }
    if (!mounted || _finished) return;
    _close(watchedFully: true);
  }

  void _cancelWatch() {
    _close(watchedFully: false);
  }

  void _close({required bool watchedFully}) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(watchedFully);
  }

  Future<void> _openSite() async {
    _cancelWatch();
    await launchUrl(
      Uri.parse(AppConfig.websiteUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelWatch();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF020B18),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'تبلیغات Tradefy',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('$_secondsLeft ثانیه'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'لطفا این صفحه را نبندید تا اتصال برقرار شود.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _openSite,
                      child: Image.asset(
                        AppConfig.assetBanner,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'پس از پایان تبلیغ، اتصال برقرار می‌شود',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
