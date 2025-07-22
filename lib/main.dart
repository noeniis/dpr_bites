import 'package:flutter/material.dart';
import 'app/app_theme.dart';
import 'features/auth/pages/login_page.dart';

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
      home: const LoginPage(),
    );
  }
}
