import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:dpr_bites/common/data/onboarding_checklist_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> logout(BuildContext context) async {
  // Clear user session or token if any
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await OnboardingChecklistStorage.reset();
  // Navigate to login page and remove all previous routes
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
