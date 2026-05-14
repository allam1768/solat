# 🕋 Solat App - Precise & Smart Prayer Companion

[![Flutter](https://img.shields.io/badge/Flutter-v3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Solat App** is a modern, high-performance prayer time application built with Flutter. It's designed to provide accurate prayer times anywhere in the world, even without an internet connection, while offering "smart" reminder features that ensure you never miss a prayer.

---

## 📲 Download

You can download the latest production-ready APK directly from Google Drive:
👉 [**Download Solat App APK**](https://drive.google.com/drive/folders/1kKgQwffShvFP57T50BWBlV82uJ5u4aR5?usp=drive_link)

---

## ✨ Key Features

### 🌍 Global & Offline Accuracy
- **Zero-Config Detection**: Automatically detects the best calculation method based on your GPS country code.
- **Fully Offline**: All calculations are done locally using the `adhan` library—no internet required.
- **Precise Location**: Integration with high-precision location services for exact timing.

### 🧠 Smart Reminder System
- **Dynamic Overlays**: A progressive reminder system that increases in intensity (Gentle -> High -> Critical) if you haven't marked your prayer as done.
- **Interactive Snooze**: Native Android overlays with "I've Prayed", "Later", and "On my way" options.
- **Smart vs. Basic Mode**: Choose between non-intrusive standard notifications or the full "Smart" overlay experience.
- **Isha Special Logic**: Custom timeout for Isha reminders to accommodate night-time usage.

### 🕌 Friday Special
- **Jumatan Mode**: Automatically labels Dhuhr as "Jumatan" on Fridays.
- **Preparation Reminders**: Dedicated notifications at 50 and 30 minutes before Friday prayer to help you prepare for the mosque.

### 🎨 Modern & Responsive UI
- **Sleek Aesthetics**: Clean, minimal design with support for Light and Dark modes.
- **Responsive Layout**: Pixel-perfect UI across different screen sizes using `ScreenUtil`.
- **Customized Onboarding**: Smooth introduction flow with gender-specific tailoring for a personalized experience.

---

## 🛠️ Technical Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [GetX](https://pub.dev/packages/get)
- **Local Storage**: [GetStorage](https://pub.dev/packages/get_storage)
- **Prayer Logic**: [Adhan Dart](https://pub.dev/packages/adhan)
- **Notifications**: [Awesome Notifications](https://pub.dev/packages/awesome_notifications)
- **Overlay Window**: [Flutter Overlay Window](https://pub.dev/packages/flutter_overlay_window) + Custom Native Kotlin implementation.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Channel Stable)
- Android Studio / VS Code
- Android Device (API 26+ recommended for best overlay experience)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/allam1768/solat.git
   ```
2. Install dependencies:
   ```bash
   cd solat
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 📦 Build Instructions (Release)

To generate the smallest possible APK for your device:
```bash
flutter build apk --release --split-per-abi
```
The optimized APKs will be located in `build/app/outputs/flutter-apk/`.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ for the Ummah.
</p>
