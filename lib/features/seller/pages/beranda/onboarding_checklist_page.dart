import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpr_bites/features/seller/pages/proses_pengajuan/proses_pengajuan_page.dart';
import 'package:dpr_bites/features/seller/pages/profil_gerai/profile_gerai_page.dart';
import 'package:dpr_bites/features/seller/pages/profil_gerai/daftar_menu_page.dart';

class OnboardingChecklistPage extends StatefulWidget {
  const OnboardingChecklistPage({super.key});

  @override
  State<OnboardingChecklistPage> createState() => _OnboardingChecklistPageState();
}

class _OnboardingChecklistPageState extends State<OnboardingChecklistPage> {
  late Future<Map<String, dynamic>> _onboardingDataFuture;

  @override
  void initState() {
    super.initState();
    _onboardingDataFuture = _getUserOnboardingData();
  }

  Future<String> _getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  Future<Map<String, dynamic>> _getUserOnboardingData() async {
    final userId = await _getCurrentUserId();
    if (userId.isEmpty) {
      throw Exception('User ID tidak ditemukan. Pastikan sudah login dan userId tersimpan.');
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data() ?? {};
    return {
      'onboardingSteps': List<bool>.from(data['onboardingSteps'] ?? [false, false, false]),
      'onboardingCompleted': data['onboardingCompleted'] ?? false,
      'userId': userId,
    };
  }

  Future<void> _updateOnboardingStep(int stepIndex) async {
    final userId = await _getCurrentUserId();
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final doc = await docRef.get();
    final data = doc.data() ?? {};
    List<bool> steps = List<bool>.from(data['onboardingSteps'] ?? [false, false, false]);
    steps[stepIndex] = true;
    bool completed = steps.every((e) => e);
    await docRef.update({
      'onboardingSteps': steps,
      'onboardingCompleted': completed,
    });
    setState(() {
      _onboardingDataFuture = _getUserOnboardingData();
    });
    if (completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    }
  }

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
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _onboardingDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Terjadi kesalahan: \\n${snapshot.error}'));
              }
              final status = List<bool>.from(snapshot.data?['onboardingSteps'] ?? [false, false, false]);
              final completed = snapshot.data?['onboardingCompleted'] ?? false;
              // Redirect jika sudah completed
              if (completed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                });
                return const SizedBox.shrink();
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
                                child: Icon(
                                  Icons.verified,
                                  color: status[0] ? Colors.grey : Color(0xFFD53D3D),
                                  size: 38,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Selesaikan proses pengajuan",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: status[0] ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Lengkapi detail informasi gerai dan metode pembayaran Anda untuk menyelesaikan proses pendaftaran kantin.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: status[0] ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: status[0]
                                            ? null
                                            : () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const ProsesPengajuanPage(),
                                                  ),
                                                );
                                                if (result == true) {
                                                  await _updateOnboardingStep(0);
                                                }
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
                                child: Icon(
                                  Icons.home,
                                  color: status[1] ? Colors.grey : Color(0xFFD53D3D),
                                  size: 38,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Profil gerai",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: status[1] ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Tarik perhatian pelanggan dengan visual menarik dan kata kunci yang tepat.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: status[1] ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: status[1]
                                            ? null
                                            : () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const ProfilGeraiPage(),
                                                  ),
                                                );
                                                if (result == true) {
                                                  await _updateOnboardingStep(1);
                                                }
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
                                child: Icon(
                                  Icons.fastfood,
                                  color: status[2] ? Colors.grey : Color(0xFFD53D3D),
                                  size: 38,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pengaturan menu",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: status[2] ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Sajikan hidangan lezat untuk dinikmati para pelanggan.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: status[2] ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: status[2]
                                            ? null
                                            : () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const DaftarMenuPage(),
                                                  ),
                                                );
                                                if (result == true) {
                                                  await _updateOnboardingStep(2);
                                                }
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
