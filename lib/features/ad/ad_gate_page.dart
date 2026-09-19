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

class _AdGatePageState extends State<AdGatePage> {
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.duration.inSeconds;
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && _secondsLeft > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _secondsLeft -= 1);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _openSite() async {
    await launchUrl(
      Uri.parse(AppConfig.websiteUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
