import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:dpr_bites/common/data/onboarding_checklist_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> logout(BuildContext context) async {
  final storage = FlutterSecureStorage();
  await storage.deleteAll();
  // Reset onboarding checklist jika ada
  await OnboardingChecklistStorage.reset();
  // Navigasi ke halaman login dan hapus semua route sebelumnya
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
