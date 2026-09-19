import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradefy_vpn/core/theme/app_theme.dart';
import 'package:tradefy_vpn/core/utils/flag_emoji.dart';
import 'package:tradefy_vpn/core/utils/subscription_codec.dart';
import 'package:tradefy_vpn/core/utils/xray_config.dart';
import 'package:tradefy_vpn/core/utils/proxy_host.dart';
import 'package:tradefy_vpn/data/models/vpn_node.dart';
import 'package:tradefy_vpn/features/home/widgets/connect_button.dart';

void main() {
  test('subscription decoder keeps plaintext share links', () {
    const body = 'vless://abc@example.com:443#one\ntrojan://x@host:443#two';
    expect(decodeSubscriptionBody(body), contains('vless://'));
  });

  test('flag emoji is generated from country code', () {
    expect(flagEmoji('DE'), isNotEmpty);
    expect(flagEmoji('US').length, greaterThan(1));
  });

  test('vpn node display name is TradefyVPN with index only', () {
    const node = VpnNode(
      id: '1',
      shareLink: 'vless://x',
      configJson: '{}',
      protocol: 'vless',
      address: '1.1.1.1',
      port: 443,
      pingMs: 120,
      countryCode: 'DE',
      country: 'Germany',
      indexInCountry: 2,
    );
    expect(node.displayName, 'TradefyVPN #2');
    expect(node.displayName, isNot(contains(flagEmoji('DE'))));
    expect(node.flag, isNotEmpty);
  });

  testWidgets('connect button shows remaining time when connected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('fa'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: ConnectButton(
            connected: true,
            busy: false,
            remainingLabel: '59:01',
            onPressed: _noop,
          ),
        ),
      ),
    );

    expect(find.textContaining('59:01'), findsOneWidget);
  });

  test('sanitizes dollar signs in trojan userinfo', () {
    const raw =
        'trojan://B9wEG%3Bg*J4P5\$Dx5gHTm@example.com:443?security=tls#name';
    final sanitized = sanitizeShareLink(raw);
    expect(sanitized, contains('%24'));
    expect(Uri.tryParse(sanitized), isNotNull);
    expect(Uri.parse(sanitized).host, 'example.com');
  });

  test('optimizeXrayConfig uses AsIs DNS strategy', () {
    const raw =
        '{"dns":{"servers":["8.8.8.8"]},"routing":{"domainStrategy":"UseIp"},"inbounds":[],"outbounds":[]}';
    final optimized = jsonDecode(optimizeXrayConfig(raw)) as Map<String, dynamic>;
    expect(optimized['routing']['domainStrategy'], 'AsIs');
    expect((optimized['dns']['servers'] as List).first, '1.1.1.1');
  });

  test('extractShareUserInfo decodes percent-encoded trojan passwords', () {
    const raw =
        'trojan://B9wEG%3Bg*J4P5\$Dx5gHTm@example.com:443?security=tls#name';
    expect(extractShareUserInfo(raw), 'B9wEG;g*J4P5\$Dx5gHTm');
  });

  test('optimizeXrayConfig writes decoded trojan password and disables sniffing', () {
    const share =
        'trojan://B9wEG%3Bg*J4P5\$Dx5gHTm@example.com:443?security=tls#name';
    const raw = '''
{
  "inbounds": [{"protocol": "socks", "port": 10807, "sniffing": {"enabled": true}}],
  "outbounds": [{
    "protocol": "trojan",
    "settings": {
      "servers": [{"password": "B9wEG%3Bg*J4P5\$Dx5gHTm", "method": "chacha20-poly1305"}]
    }
  }],
  "routing": {"domainStrategy": "UseIp"}
}
''';
    final optimized =
        jsonDecode(optimizeXrayConfig(raw, shareLink: share)) as Map<String, dynamic>;
    expect(optimized['inbounds'][0]['port'], 10808);
    expect(optimized['inbounds'][0]['sniffing']['enabled'], isFalse);
    expect(
      optimized['outbounds'][0]['settings']['servers'][0]['password'],
      'B9wEG;g*J4P5\$Dx5gHTm',
    );
    expect(
      optimized['outbounds'][0]['settings']['servers'][0].containsKey('method'),
      isFalse,
    );
  });

  test('applyVpnRuntimeSettings keeps compact JSON without fake DNS', () {
    const raw =
        '{"dns":{"servers":["1.1.1.1"]},"fakedns":[],"routing":{"domainStrategy":"AsIs"},"inbounds":[],"outbounds":[]}';
    final runtime =
        jsonDecode(applyVpnRuntimeSettings(raw)) as Map<String, dynamic>;
    expect(runtime.containsKey('fakedns'), isFalse);
    expect((runtime['dns']['servers'] as List).first, '1.1.1.1');
  });

  test('camouflage hosts are not used as server country', () {
    expect(isCamouflageHost('www.speedtest.net'), isTrue);
    expect(isCamouflageHost('104.21.23.10'), isTrue);
    expect(isCamouflageHost('172.67.209.44'), isTrue);
    expect(isCamouflageHost('example.workers.dev'), isTrue);
    expect(isCamouflageHost('1.1.1.1'), isFalse);
  });

  test('extractPreferredHost skips cloudflare fronts', () {
    const raw = '''
{
  "outbounds": [{
    "protocol": "vless",
    "settings": {"vnext": [{"address": "104.21.23.10"}]},
    "streamSettings": {
      "tlsSettings": {"serverName": "www.speedtest.net"},
      "wsSettings": {"host": "panel.example.workers.dev"}
    }
  }]
}
''';
    expect(extractPreferredHost(raw), isNull);
  });
}

void _noop() {}
