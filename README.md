# DPR Bites 🍽️

Aplikasi pemesanan makanan sederhana untuk anggota dan staf DPR RI menggunakan Flutter.

## 📱 Fitur

- Daftar menu makanan dan minuman
- Keranjang belanja
- Riwayat pesanan
- Profil pengguna sederhana

## 🛠️ Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Database**: SQLite (local) / Firebase (cloud)
- **Authentication**: Firebase Auth

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Android Studio / VS Code
- Git

### Installation

```bash
# Clone repository
git clone https://github.com/dpr-ri/dpr-bites.git
cd dpr-bites

# Install dependencies
flutter pub get

# Generate code (untuk Riverpod)
dart run build_runner build

# Run app
flutter run
```

## 📂 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── routes.dart
├── common/
│   ├── data/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   ├── menu/
│   ├── cart/
│   └── profile/
└── shared/
    ├── models/
    ├── services/
    └── constants/
```

## 🔧 Development

### Menjalankan Aplikasi

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Build APK
flutter build apk

# Generate code (Riverpod)
dart run build_runner build

# Watch mode (auto-generate)
dart run build_runner watch
```

### Testing

```bash
# Run tests
flutter test

# Run widget tests
flutter test test/widget_test.dart
```

## 📱 Build & Deploy

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS
```bash
# Build iOS
flutter build ios --release
```

## 🤝 Untuk Magang

### Task yang bisa dikerjakan:
1. **Feature Development** - Kembangkan fitur baru di folder `features/`
2. **State Management** - Buat providers baru dengan Riverpod
3. **Navigation** - Setup routing dengan GoRouter di `app/router.dart`
4. **UI Components** - Buat reusable widgets di `common/widgets/`
5. **Data Layer** - Implementasi models dan services
6. **Theme & Styling** - Konsistensi tema di `common/theme/`
7. **Bug Fixes** - Perbaiki bug yang ditemukan
8. **Testing** - Tulis unit test dan widget test
9. **Utils & Helpers** - Buat helper functions di `common/utils/`

### Coding Guidelines:
- Gunakan arsitektur feature-based (satu folder per feature)
- Pakai Riverpod untuk state management (buat providers di setiap feature)
- Gunakan GoRouter untuk navigation (declarative routing)
- Pisahkan logic bisnis dari UI (repository pattern)
- Buat reusable widgets di `common/widgets/`
- Gunakan consistent naming convention
- Tambahkan comment untuk fungsi kompleks
- Follow Flutter best practices
- Test di berbagai device size

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Firebase Flutter](https://firebase.flutter.dev/)

## 🐛 Bug Report

Jika menemukan bug, silakan buat issue di GitHub dengan format:
- **Device**: Android/iOS version
- **Steps to reproduce**: Langkah-langkah
- **Expected behavior**: Yang diharapkan
- **Actual behavior**: Yang terjadi
- **Screenshots**: Jika ada


**Selamat coding! 🚀**
