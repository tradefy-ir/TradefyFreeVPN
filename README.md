# TradefyVPN

<p align="center">
  <img src="images/AppLogo.png" alt="TradefyVPN" width="128" />
</p>

<p align="center">
  <strong>فیلترشکن رایگان اندروید با هسته Xray</strong><br />
  Free Android VPN powered by Xray
</p>

<p align="center">
  <a href="https://github.com/tradefy-ir/TradefyFreeVPN/releases/latest"><img alt="GitHub release" src="https://img.shields.io/github/v/release/tradefy-ir/TradefyFreeVPN?style=flat-square" /></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" /></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-green?style=flat-square" />
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Android-04599C?style=flat-square" />
</p>

<p align="center">
  <img src="images/startApp.png" alt="TradefyVPN splash" width="280" />
</p>

TradefyVPN یک کلاینت VPN متن‌باز مخصوص **اندروید** است. لینک‌های اشتراک Xray را دریافت می‌کند، پینگ واقعی هر سرور را می‌سنجد و اتصال را از طریق تونل سیستم‌عامل (`VpnService`) برقرار می‌کند.

TradefyVPN is an open-source **Android-only** VPN client. It fetches Xray subscription links, measures real server delay, and connects through Android `VpnService`.

وب‌سایت: [tradefy.ir](https://www.tradefy.ir/fa)

---

## دانلود

آخرین نسخه را از صفحهٔ [Releases](https://github.com/tradefy-ir/TradefyFreeVPN/releases/latest) بگیرید.

| فایل | مناسب برای |
| --- | --- |
| `app-arm64-v8a-release.apk` | بیشتر گوشی‌های امروزی (پیشنهادی) |
| `app-armeabi-v7a-release.apk` | گوشی‌های ۳۲ بیتی قدیمی |
| `app-x86_64-release.apk` | برخی تبلت‌ها و امولاتور |
| `app-release.apk` | نسخهٔ Universal (هر سه معماری در یک فایل) |

حداقل اندروید: **۷.۰ (API 24)**

اگر نسخهٔ قبلی با امضای دیگری نصب شده باشد، اول آن را حذف کنید.

---

## ویژگی‌ها

- هستهٔ **Xray** از طریق [`flutter_v2ray_client`](https://pub.dev/packages/flutter_v2ray_client)
- دریافت خودکار کانفیگ از لینک‌های اشتراک (VLESS، Trojan و پروتکل‌های سازگار)
- تست پینگ واقعی، هم‌زمان شبیه V2rayNG
- نام‌گذاری سرورها به صورت `TradefyVPN #n`
- رابط فارسی راست‌به‌چپ
- تبلیغ ۱۵ ثانیه‌ای قبل از اتصال
- قطع خودکار بعد از حداکثر **۱ ساعت** نشست
- تازه‌سازی لیست اشتراک هنگام باز شدن برنامه و هر ساعت یک‌بار (بدون قطع اتصال فعال)
- قطع اتصال از نوتیفیکیشن VPN

---

## ساخت از سورس

نیازمندی‌ها:

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK مطابق `pubspec.yaml`)
- Android SDK (API 24 به بالا)
- JDK ۱۷ یا نسخه‌ای که Android Studio همراه دارد

```bash
git clone https://github.com/tradefy-ir/TradefyFreeVPN.git
cd TradefyFreeVPN
flutter pub get
```

اجرا روی دستگاه متصل:

```bash
flutter run
```

خروجی APK:

```bash
# Universal
flutter build apk --release

# جداگانه برای هر معماری
flutter build apk --release --split-per-abi
```

فایل‌ها در مسیر زیر ساخته می‌شوند:

```text
build/app/outputs/flutter-apk/
```

برای انتشار عمومی، یک keystore اختصاصی بسازید و مسیر آن را در `android/key.properties` قرار دهید. این فایل و خود keystore را هرگز در گیت قرار ندهید.

---

## پیکربندی

تنظیمات اصلی در [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart) است:

- لینک‌های اشتراک Xray
- مدت تبلیغ قبل از اتصال (۱۵ ثانیه)
- سقف نشست (۱ ساعت)
- فاصلهٔ تازه‌سازی اشتراک
- آدرس سایت Tradefy

---

## ساختار پروژه

```text
lib/
  core/          تنظیمات، تم و ابزارهای Xray
  data/          اشتراک، کش و مدل‌ها
  features/      صفحات اسپلش، خانه و تبلیغ اتصال
  services/      هسته Xray، پینگ و نشست
  state/         کنترلر VPN
android/         VpnService، نوتیفیکیشن و امضای انتشار
images/          لوگو، اسپلش و بنر
```

---

## English

TradefyVPN is a free, open-source Android VPN built with Flutter and Xray.

- Fetches subscription configs and shows live ping
- Connects with Android VPN (not proxy-only mode)
- Shows a 15-second ad gate before connecting
- Auto-disconnects after a 1-hour session
- Persian RTL UI

Clone, then `flutter pub get` and `flutter build apk --release`. Prefer the `arm64-v8a` APK on modern phones.

---

## مجوز

این پروژه تحت مجوز [MIT](LICENSE) منتشر می‌شود.

---

## سلب مسئولیت

این برنامه برای دسترسی آزاد به اینترنت ساخته شده است. استفاده از آن باید مطابق قوانین محل زندگی شما باشد. نویسندگان مسئولیتی در قبال نحوهٔ استفاده از نرم‌افزار ندارند.
