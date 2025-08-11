import 'package:dpr_bites/features/seller/pages/lainnya/menu/menu_resto.dart';
import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';

class PeriksaMenuPage extends StatelessWidget {
  const PeriksaMenuPage({super.key});

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
              fontSize: 25,
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
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage(
                        'lib/assets/images/waroenk88.jpeg',
                      ),
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
                const Text(
                  "Nasi Pecel",
                  style: TextStyle(
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
                const Text(
                  "Rp 20.000",
                  style: TextStyle(
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
                const Text(
                  "Hidangan khas Jawa yang terdiri dari nasi putih hangat, kacang panjang dan kemangi, dipadu dengan sambal gurih pedas yang khas. Disajikan bersama pelengkap ayam serundeng dan telur rebus.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
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
                      onPressed: () {
                        Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuRestoPage()),
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
