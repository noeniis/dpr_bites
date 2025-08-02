import 'package:flutter/material.dart';
import 'login_page.dart';

Future<void> logout(BuildContext context) async {
  
  // Navigate to login page and remove all previous routes
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
