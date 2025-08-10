import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/features/seller/pages/proses_pengajuan/proses_pengajuan_page.dart';
import 'package:dpr_bites/features/seller/pages/profil_gerai/profile_gerai_page.dart';
import 'package:dpr_bites/features/seller/pages/profil_gerai/daftar_menu_page.dart';
import 'package:dpr_bites/common/data/onboarding_checklist_storage.dart';

class OnboardingChecklistPage extends StatelessWidget {
  const OnboardingChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            )
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<bool>>(
            future: OnboardingChecklistStorage.getStatus(),
            builder: (context, snapshot) {
              final status = snapshot.data ?? [false, false, false];
              print('Checklist status: $status');
              // Redirect jika semua selesai
              if (status.every((e) => e)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                });
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      "Selesaikan persiapan toko Anda",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF602829),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // CARD 1: Selesaikan proses pengajuan
                    CustomEmptyCard(
                      margin: const EdgeInsets.only(bottom: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: status[0] ? Colors.grey[300] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 14, top: 2),
                                child: Icon(Icons.verified, color: status[0] ? Colors.grey : Color(0xFFD53D3D), size: 38),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Selesaikan proses pengajuan",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: status[0] ? Colors.grey : Colors.black),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Lengkapi detail informasi gerai dan metode pembayaran Anda untuk menyelesaikan proses pendaftaran kantin.",
                                      style: TextStyle(fontSize: 14, color: status[0] ? Colors.grey : Colors.black),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: status[0]
                                            ? null
                                            : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const ProsesPengajuanPage()),
                                                );
                                              },
                                        child: Text(
                                          status[0] ? "Sudah selesai" : "Selesaikan sekarang",
                                          style: TextStyle(
                                            color: status[0] ? Colors.grey : Color(0xFFD53D3D),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // CARD 2: Profil gerai
                    CustomEmptyCard(
                      margin: const EdgeInsets.only(bottom: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: status[1] ? Colors.grey[300] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 14, top: 2),
                                child: Icon(Icons.home, color: status[1] ? Colors.grey : Color(0xFFD53D3D), size: 38),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Profil gerai",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: status[1] ? Colors.grey : Colors.black),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Tarik perhatian pelanggan dengan visual menarik dan kata kunci yang tepat.",
                                      style: TextStyle(fontSize: 14, color: status[1] ? Colors.grey : Colors.black),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: status[1] ? null : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const ProfilGeraiPage()),
                                          );
                                        },
                                        child: Text(
                                          status[1] ? "Sudah selesai" : "Lengkapi profil",
                                          style: TextStyle(
                                            color: status[1] ? Colors.grey : Color(0xFFD53D3D),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // CARD 3: Pengaturan menu
                    CustomEmptyCard(
                      child: Container(
                        decoration: BoxDecoration(
                          color: status[2] ? Colors.grey[300] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 14, top: 2),
                                child: Icon(Icons.fastfood, color: status[2] ? Colors.grey : Color(0xFFD53D3D), size: 38),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pengaturan menu",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: status[2] ? Colors.grey : Colors.black),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Sajikan hidangan lezat untuk dinikmati para pelanggan.",
                                      style: TextStyle(fontSize: 14, color: status[2] ? Colors.grey : Colors.black),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: status[2] ? null : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const DaftarMenuPage()),
                                          );
                                        },
                                        child: Text(
                                          status[2] ? "Sudah selesai" : "Atur menu",
                                          style: TextStyle(
                                            color: status[2] ? Colors.grey : Color(0xFFD53D3D),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
