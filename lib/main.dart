import 'package:flutter/material.dart';
import 'features/seller/pages/beranda/dashboard_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/user/pages/home/home_page.dart';
import 'features/user/pages/address/address_page.dart';
import 'features/user/pages/address/address_add_page.dart';
import 'features/user/pages/favorit/favorit.dart';
import 'features/user/pages/history/history_page.dart';
import 'features/user/pages/profile/profile_page.dart';
import 'features/seller/pages/beranda/onboarding_checklist_page.dart';
import 'features/auth/pages/reset_password_page.dart';
import 'features/koperasi/homepage_koperasi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  String? token = await storage.read(key: 'jwt_token');
  String? role = await storage.read(key: 'role');
  String? step1 = await storage.read(key: 'step1');
  String? step2 = await storage.read(key: 'step2');
  String? step3 = await storage.read(key: 'step3');
  runApp(MyApp(token: token, role: role, step1: step1, step2: step2, step3: step3));
}

class MyApp extends StatelessWidget {
  final String? token;
  final String? role;
  final String? step1;
  final String? step2;
  final String? step3;
  const MyApp({super.key, this.token, this.role, this.step1, this.step2, this.step3});

  bool _isStepComplete() {
    return step1 == '1' && step2 == '1' && step3 == '1';
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;
    if (token == null) {
      homeWidget = const LoginPage();
    } else if (role == '1') {
      homeWidget = _isStepComplete()
          ? const SellerDashboardPage()
          : const OnboardingChecklistPage();
    } else if (role == '2') {
      homeWidget = const HomepageKoperasi();
    } else {
      homeWidget = const HomePage();
    }
    return MaterialApp(
      title: 'DPR Bites',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mainTheme,
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/address': (context) => const AddressPage(),
        '/address_add': (context) => const AddressAddPage(),
        '/favorit': (context) => const FavoritPage(),
        '/history': (context) => const HistoryPage(),
        '/profile': (context) => const ProfilePage(),
        '/onboarding_checklist': (context) => const OnboardingChecklistPage(),
        '/dashboard': (context) => const SellerDashboardPage(),
        '/reset-password': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ResetPasswordPage(email: args['email'], otp: args['otp']);
        },
        '/koperasi': (context) => const HomepageKoperasi(),
      },
      home: homeWidget,
    );
  }
}
