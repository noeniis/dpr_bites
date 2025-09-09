import 'package:flutter/material.dart';
import 'features/seller/pages/beranda/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Migration: if id_users is stored as string but not as int, try to normalize it
  try {
    final prefs = await SharedPreferences.getInstance();
    final intVal = prefs.getInt('id_users');
    if (intVal == null) {
      final s = prefs.getString('id_users');
      if (s != null) {
        final parsed = int.tryParse(s);
        if (parsed != null) await prefs.setInt('id_users', parsed);
      }
    }
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DPR Bites',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mainTheme,
      initialRoute: '/login',
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
      },
      home: const LoginPage(),
    );
  }
}
