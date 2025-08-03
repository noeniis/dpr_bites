import 'package:dpr_bites/features/seller/pages/lainnya/menu/menu_resto.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';

class PeriksaMenuPage extends StatelessWidget {
  final Map<String, dynamic> menuData;
  const PeriksaMenuPage({super.key, required this.menuData});

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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "Periksa Menu",
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Afacad',
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Menu
                menuData['imageUrl'] != null && menuData['imageUrl'] != ''
                    ? Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(menuData['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: const Center(child: Text("Belum ada gambar")),
                      ),
                const SizedBox(height: 20),
                const Text(
                  "Nama hidangan",
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  menuData['name'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Harga",
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp ${menuData['price'] ?? 0}",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Deskripsi",
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  menuData['description'] ?? '',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButtonKotak(
                      text: "Buat menu",
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance.collection('menus').add({
                            ...menuData,
                            'createdAt': Timestamp.fromDate(menuData['createdAt']),
                            'editedAt': Timestamp.fromDate(menuData['editedAt']),
                          });
                          final userId = menuData['userId'] ?? '';
                          final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
                          final doc = await userDoc.get();
                          List<bool> steps = List<bool>.from(doc.data()?['onboardingSteps'] ?? [false, false, false]);
                          steps[2] = true;
                          bool completed = steps.every((e) => e);
                          await userDoc.update({
                            'onboardingSteps': steps,
                            'onboardingCompleted': completed,
                          });
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const MenuRestoPage()),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menyimpan menu: $e')),
                          );
                        }
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
