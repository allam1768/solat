<div align="center">
  <!-- Ganti URL denga path icon atau logo aplikasi Anda jika ada -->
  <img src="assets/icons/logo.svg" alt="Solat App Icon" width="120">

# Solat App 🕌

**Aplikasi pengingat dan jadwal sholat akurat berdasarkan lokasi pengguna secara real-time.**

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat-square&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![GetX](https://img.shields.io/badge/State_Management-GetX-%23E0A3F.svg?style=flat-square)](https://pub.dev/packages/get)

</div>

---

## 🌟 Fitur Utama

- 📍 **Deteksi Lokasi Otomatis**: Mendapatkan jadwal sholat akurat (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) dengan menyesuaikan titik koordinat GPS perangkat Anda.
- 🕋 **Akurasi Tinggi**: Terintegrasi langsung dengan sumber data terpercaya dari [Aladhan API](https://aladhan.com/prayer-times-api).
- 🔔 **Notifikasi & Overlay Widget**: Pengingat cerdas (Native Alarm & Push Notification) ketika masuknya waktu sholat.
- ⚡ **Cepat & Ringan**: Dibangun menggunakan _State Management_ **GetX** untuk perpindahan status antarmuka yang _seamless_ tanpa kendala _lag_.

## Unduh Aplikasi (APK)

Anda dapat memuat dan menginstal aplikasi langsung ke perangkat Android Anda melalui _link_ Google Drive berikut:
👉 **[Download Solat App (APK)](https://drive.google.com/drive/folders/1kKgQwffShvFP57T50BWBlV82uJ5u4aR5?usp=drive_link)**

## 📸 Tampilan Aplikasi

|                            Beranda Waktu                             |                           Informasi Jadwal                           |
| :------------------------------------------------------------------: | :------------------------------------------------------------------: |
| <img src="assets/images/Screenshot_20260226-205526.png" width="220"> | <img src="assets/images/Screenshot_20260226-205534.png" width="220"> |

## 🛠️ Teknologi & Library

Proyek ini mengandalkan beberapa pustaka unggulan untuk memastikan performa yang mumpuni:

- **[GetX](https://pub.dev/packages/get)** – Routing, State Management, & Dependency Injection.
- **[Geolocator](https://pub.dev/packages/geolocator) & [Geocoding](https://pub.dev/packages/geocoding)** – Konversi koordinat menjadi nama kota (Reverse Geocoding).
- **[Awesome Notifications](https://pub.dev/packages/awesome_notifications)** – Konfigurasi pemberitahuan latar belakang (Background & Foreground Notif).
- **HTTP/REST** – Integrasi data komunikasi antar server.

## 🚀 Cara Menjalankan Project

Ikuti perintah singkat berikut untuk mengkonfigurasi proyek ini di komputer lokal Anda:

1. **Clone repositori ini:**
   ```bash
   git clone https://github.com/allam1768/solat.git
   ```
2. **Pindah ke direktori proyek:**
   ```bash
   cd solat
   ```
3. **Instal seluruh _dependencies_ Flutter:**
   ```bash
   flutter pub get
   ```
4. **Jalankan Aplikasi:** *(Gunakan emulator Android/iOS atau *real device*)*
   ```bash
   flutter run
   ```

---

<div align="center">
  <b>Dibuat dengan ❤️ untuk kemudahan beribadah</b>
</div>
