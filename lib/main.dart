import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/seller/pages/beranda/dashboard_page.dart';
import 'app/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/user/pages/home/home_page.dart';
import 'features/user/pages/favorit/favorit.dart';
import 'features/user/pages/history/history_page.dart';
import 'features/user/pages/profile/profile_page.dart';
import 'features/seller/pages/beranda/onboarding_checklist_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/favorit': (context) => const FavoritPage(),
        '/history': (context) => const HistoryPage(),
        '/profile': (context) => const ProfilePage(),
        '/onboarding_checklist': (context) => const OnboardingChecklistPage(),
        '/dashboard': (context) => const SellerDashboardPage(),
      },
      home: const LoginPage(),
    );
  }
}
