import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/features/seller/pages/pesanan/pesanan_page.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/profil_seller.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/menu/menu_resto.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/ulasan.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/kelola_gerai.dart';
import 'package:dpr_bites/features/auth/pages/login_page.dart';

class SellerDashboardPage extends StatelessWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data, bisa diganti provider
    final saldo = 50000;
    final pesananBaru = 2;
    final sedangDisiapkan = 1;
    final selfPickup = 0;
    final pesananAntar = 1;
    DateTime? selectedDate;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const Icon(
            Icons.storefront,
            color: Color(0xFFD53D3D),
            size: 24,
          ),
          title: Text(
            "Waroeng Kenyank 88",
            style: const TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FILTER & RINGKASAN
                CustomEmptyCard(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Filter Isi Saldo & Ringkasan Pesanan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Fungsi pilih tanggal tidak perlu jalan, hanya UI
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Pilih Tanggal",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Ringkasan dummy
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Total Saldo Masuk:",
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Rp 50.000",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Total Pesanan:",
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "4",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // TOP ROW: Saldo (full width)
                CustomEmptyCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.currency_exchange,
                              color: Colors.green,
                              size: 22,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Saldo",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rp $saldo",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ROW: Pesanan
                Row(
                  children: [
                    Expanded(
                      child: CustomEmptyCard(
                        margin: const EdgeInsets.only(right: 10, bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Pesanan Baru",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$pesananBaru",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomEmptyCard(
                        margin: const EdgeInsets.only(left: 10, bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Sedang Disiapkan",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$sedangDisiapkan",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ROW: Self Pickup & Pesan Antar
                Row(
                  children: [
                    Expanded(
                      child: CustomEmptyCard(
                        margin: const EdgeInsets.only(right: 10, bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Self Pickup",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$selfPickup",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomEmptyCard(
                        margin: const EdgeInsets.only(left: 10, bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Pesan Antar",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$pesananAntar",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // MENU
                const Text(
                  "Akun",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.person_outline,
                    color: Colors.black,
                  ),
                  title: const Text("Profil penjual"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilSellerPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book, color: Colors.black),
                  title: const Text("Menu Gerai"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuRestoPage()),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_border, color: Colors.black),
                  title: const Text("Ulasan"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UlasanPage()),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.monetization_on,
                    color: Colors.black,
                  ),
                  title: const Text("Kelola Gerai"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KelolaProfilGeraiPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Color(0xFFD53D3D)),
                  title: const Text(
                    "Keluar",
                    style: TextStyle(
                      color: Color(0xFFD53D3D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 60), // for bottom nav space
              ],
            ),
          ),
        ),
        // BOTTOM NAV BAR
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(
            0xFFF9D3D3,
          ).withValues(red: 0.85, green: 0.85, blue: 0.85, alpha: 1),
          selectedItemColor: const Color(0xFFD53D3D),
          unselectedItemColor: Colors.black54,
          currentIndex: 0, // branda (home)
          onTap: (i) {
            if (i == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PesananPage()),
              );
            }
            // Tab 0 (Beranda) does nothing since already here
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: "Pesanan",
            ),
          ],
        ),
      ),
    );
  }
}
