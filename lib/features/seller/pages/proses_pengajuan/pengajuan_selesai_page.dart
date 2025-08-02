import 'package:dpr_bites/features/seller/pages/beranda/onboarding_checklist_page.dart';
import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanSelesaiPage extends StatelessWidget {
  static Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }
  const PengajuanSelesaiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // Ceklis Icon
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Terima kasih telah mengirimkan pengajuan gerai Anda",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Pengajuan gerai Anda telah berhasil. Silakan lanjutkan dengan mengatur gerai dan menyusun menu Anda.",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButtonKotak(
                      text: "Lanjutkan ke beranda",
                      onPressed: () async {
                        // Update langkah 0 di Firestore
                        final userId = await PengajuanSelesaiPage.getCurrentUserId();
                        final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
                        final doc = await docRef.get();
                        final data = doc.data() ?? {};
                        List<bool> steps = List<bool>.from(data['onboardingSteps'] ?? [false, false, false]);
                        steps[0] = true;
                        bool completed = steps.every((e) => e);
                        await docRef.update({
                          'onboardingSteps': steps,
                          'onboardingCompleted': completed,
                        });
                        // Kembali ke onboarding checklist dan trigger reload
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const OnboardingChecklistPage()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
}
