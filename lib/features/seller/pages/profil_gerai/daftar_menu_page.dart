import 'package:dpr_bites/features/seller/pages/profil_gerai/tambah_menu_page.dart';
import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class DaftarMenuPage extends StatelessWidget {
  const DaftarMenuPage({super.key});

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 18),
                const Text(
                  "Daftar Menu",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Color(0xFF602829),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'lib/assets/images/chalkboard_menu.jpeg',
                  height: 250,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Selamat datang di menu Anda!\n\nDi halaman ini, Anda dapat mulai membuat dan mengelola menu gerai Anda. Mulailah dengan menambahkan hidangan untuk ditampilkan kepada pelanggan.",
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Inter',
                      color: Colors.black87,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: CustomButtonKotak(
                    text: "Tambahkan Menu",
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TambahMenuPage()),
                    );
                  },
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
