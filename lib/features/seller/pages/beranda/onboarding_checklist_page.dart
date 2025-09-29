import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/features/seller/pages/proses_pengajuan/proses_pengajuan_page.dart';
import 'package:dpr_bites/features/seller/pages/profil_gerai/profile_gerai_page.dart';
import 'package:dpr_bites/features/seller/pages/profil_gerai/daftar_menu_page.dart';
import 'package:dpr_bites/features/seller/models/seller_user_model.dart';
import 'package:dpr_bites/features/seller/services/onboarding_checklist_service.dart';
import 'package:dpr_bites/features/auth/pages/logout.dart';


class OnboardingChecklistPage extends StatefulWidget {
  const OnboardingChecklistPage({super.key});

  @override
  State<OnboardingChecklistPage> createState() => _OnboardingChecklistPageState();
}

class _OnboardingChecklistPageState extends State<OnboardingChecklistPage> {
  bool isLoading = true;
  SellerUserModel? userModel;
  List<bool> status = [false, false, false];
  String statusPengajuanGerai = '';
  bool _pendingDialogShown = false;
  @override
  void initState() {
  super.initState();
  _loadUserStepStatus();
  _checkGeraiPengajuanStatus();
  }

  Future<void> _loadUserStepStatus() async {
    final user = await OnboardingChecklistService.fetchSellerUserStatus();
    if (user != null) {
      debugPrint('[ONBOARDING] step1: [33m${user.step1}[0m, step2: [33m${user.step2}[0m, step3: [33m${user.step3}[0m, statusPengajuanGerai: [33m${user.statusPengajuanGerai}[0m');
      userModel = user;
      statusPengajuanGerai = user.statusPengajuanGerai;
      setState(() {
        status = [
          user.step1 == 1,
          user.step2 == 1,
          user.step3 == 1 && user.statusPengajuanGerai == 'approved',
        ];
        isLoading = false;
      });
    } else {
      debugPrint('[ONBOARDING] user null, gagal ambil status');
      setState(() { isLoading = false; });
    }
    _checkGeraiPengajuanStatus();
  }

  Future<void> _checkGeraiPengajuanStatus() async {
    if (userModel == null) return;

    // Ditolak
    if (userModel!.statusPengajuanGerai == 'rejected') {
      final alasanTolak = userModel!.alasanTolak;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Pengajuan Gerai Ditolak'),
              content: Text(
                'Pengajuan gerai Anda ditolak.\n'
                'Alasan: ${alasanTolak.isNotEmpty ? alasanTolak : "-"}\n'
                'Kirim ulang seluruh data hingga peringatan ini tidak muncul.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
      return;
    }

    
    if (!_pendingDialogShown && userModel!.statusPengajuanGerai == 'pending' && userModel!.step1 == 1 && userModel!.step2 == 1) {
      _pendingDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Pengajuan dalam Peninjauan'),
              content: const Text(
                'Gerai Anda masih dalam tahap peninjauan oleh koperasi.\n'
                'Mohon tunggu proses verifikasi. Anda akan diberitahu jika ada pembaruan.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!isLoading && status.every((e) => e)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    }
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
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              tooltip: 'Logout',
              onPressed: () async {
                await logout(context);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
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
                                        MaterialPageRoute(builder: (_) => const ProfileGeraiPage()),
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
                      color: (statusPengajuanGerai == 'approved' && status[2]) ? Colors.grey[300] : (statusPengajuanGerai == 'approved' ? Colors.white : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 14, top: 2),
                            child: Icon(Icons.fastfood, color: (statusPengajuanGerai == 'approved' && status[2]) ? Colors.grey : (statusPengajuanGerai == 'approved' ? Color(0xFFD53D3D) : Colors.grey), size: 38),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pengaturan menu",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: (statusPengajuanGerai == 'approved' && status[2]) ? Colors.grey : (statusPengajuanGerai == 'approved' ? Colors.black : Colors.grey)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Sajikan hidangan lezat untuk dinikmati para pelanggan.",
                                  style: TextStyle(fontSize: 14, color: (statusPengajuanGerai == 'approved' && status[2]) ? Colors.grey : (statusPengajuanGerai == 'approved' ? Colors.black : Colors.grey)),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: (statusPengajuanGerai == 'approved' && !status[2]) ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const DaftarMenuPage()),
                                      );
                                    } : null,
                                    child: Text(
                                      (statusPengajuanGerai == 'approved' && status[2]) ? "Sudah selesai" : (statusPengajuanGerai == 'approved' ? "Atur menu" : "Menunggu verifikasi gerai"),
                                      style: TextStyle(
                                        color: (statusPengajuanGerai == 'approved' && status[2]) ? Colors.grey : (statusPengajuanGerai == 'approved' ? Color(0xFFD53D3D) : Colors.grey),
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
          ),
        ),
      ),
    );
  }
}
