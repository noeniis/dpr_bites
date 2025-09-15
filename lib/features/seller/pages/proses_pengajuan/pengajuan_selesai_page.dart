import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/onboarding_checklist_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/seller_user_service.dart';

class PengajuanSelesaiPage extends StatelessWidget {
  const PengajuanSelesaiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
            onPressed: () => Navigator.pop(context),
          ),
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
                        // Ambil id_users dari flutter_secure_storage
                        final storage = FlutterSecureStorage();
                        final idUsers = await storage.read(key: 'id_users') ?? '';
                        await SellerUserService.updateStepSellerStatus(idUsers, step1: 1);
                        await OnboardingChecklistStorage.setStatus(0, true);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/onboarding_checklist',
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
