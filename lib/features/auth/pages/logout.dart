import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:dpr_bites/common/data/onboarding_checklist_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> logout(BuildContext context) async {
  // Hapus id_users dari SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('id_users');
  // Reset onboarding checklist jika ada
  await OnboardingChecklistStorage.reset();
  // Navigasi ke halaman login dan hapus semua route sebelumnya
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
