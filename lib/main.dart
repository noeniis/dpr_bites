import 'package:flutter/material.dart';
import 'app/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/user/pages/home/home_page.dart';
import 'features/user/pages/favorit/favorit.dart';
import 'features/user/pages/history/history_page.dart';
import 'features/user/pages/profile/profile_page.dart';

void main() {
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
      },
      home: const LoginPage(),
    );
  }
}
