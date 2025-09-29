import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/features/seller/services/dashboard_service.dart';
import 'package:dpr_bites/features/seller/models/dashboard_rekap_model.dart';
import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/features/seller/pages/pesanan/pesanan_page.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/profil_seller.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/menu/menu_resto.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/ulasan.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/kelola_gerai.dart';
import 'package:dpr_bites/features/auth/pages/logout.dart';
import 'rekap_pesanan_seller_page.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  String? _namaGerai;
  bool _loadingGerai = true;

  DashboardRekapModel? _rekapModel;
  bool _loadingRekap = true;

  String? _idGerai;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchNamaGerai();
  }

  Future<void> _fetchNamaGerai() async {
    final storage = FlutterSecureStorage();
    final idUser = await storage.read(key: 'id_users');
    if (idUser == null) {
      if (!mounted) return;
      setState(() { _namaGerai = '-'; _loadingGerai = false; });
      return;
    }
    try {
      final dataGerai = await DashboardService.fetchGeraiByUser(idUser);
      final idGerai = dataGerai?['id_gerai']?.toString();
      if (dataGerai != null && dataGerai['nama_gerai'] != null) {
        if (idGerai != null && idGerai.isNotEmpty) {
          await storage.write(key: 'id_gerai', value: idGerai);
          if (!mounted) return;
          setState(() {
            _idGerai = idGerai;
            _namaGerai = dataGerai['nama_gerai'] ?? '-';
            _loadingGerai = false;
          });
          await _fetchRekapPesanan(); 
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() { _namaGerai = '-'; _loadingGerai = false; });
  }

  Future<void> _fetchRekapPesanan() async {
    if (!mounted) return;
    setState(() { _loadingRekap = true; });

  final storage = FlutterSecureStorage();
  final idGerai = _idGerai ?? await storage.read(key: 'id_gerai');
    if (idGerai == null) {
      if (!mounted) return;
      setState(() { _loadingRekap = false; });
      return;
    }

    final date = _selectedDate ?? DateTime.now();
    final tanggal = "${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";

    final result = await DashboardService.fetchRekap(idGerai: idGerai, tanggal: tanggal);
    if (!mounted) return;
    setState(() {
      _rekapModel = result;
      _loadingRekap = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchRekapPesanan();
    }
  }

  @override
  Widget build(BuildContext context) {
    String tanggalLabel = _selectedDate == null
        ? "Pilih Tanggal"
        : "${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}";

    int pesananBaru = _rekapModel?.pesananBaru ?? 0;
    int sedangDisiapkan = _rekapModel?.sedangDisiapkan ?? 0;
    int selfPickup = _rekapModel?.selfPickup ?? 0;
    int pesananAntar = _rekapModel?.pesananAntar ?? 0;
    int totalSaldo = _rekapModel?.totalSaldo ?? 0;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const Icon(Icons.storefront, color: Color(0xFFD53D3D), size: 24),
          title: _loadingGerai
              ? const SizedBox(height: 18, width: 120, child: LinearProgressIndicator())
              : Text(
                  _namaGerai ?? '-',
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
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ringkasan Pesanan dan Saldo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFD53D3D), width: 1.2),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tanggalLabel,
                                        style: const TextStyle(fontSize: 14, color: Color(0xFF602829), fontWeight: FontWeight.w500),
                                      ),
                                      Icon(Icons.calendar_today, size: 18, color: Color(0xFFD53D3D)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedDate == null ? "Saldo hari ini:" : "Saldo tanggal:", style: const TextStyle(fontSize: 14)),
                            _loadingRekap
                                ? const SizedBox(width: 24, height: 16, child: LinearProgressIndicator())
                                : Text("Rp $totalSaldo", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD53D3D))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Pesanan:", style: TextStyle(fontSize: 14)),
                            _loadingRekap
                                ? const SizedBox(width: 24, height: 16, child: LinearProgressIndicator())
                                : Text("${pesananBaru + sedangDisiapkan + selfPickup + pesananAntar}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD53D3D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.table_chart),
                            label: const Text("Lihat Rekap Pesanan Seller"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RekapPesananSellerPage(),
                                ),
                              );
                            },
                          ),
                        ),

                      ],
                    ),
                  ),
                ),


                // ROW 1: Pesanan Baru & Disiapkan (klik → PesananPage dengan filter)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PesananPage(initialFilter: 'Konfirmasi Ketersediaan'),
                            ),
                          );
                        },
                        child: CustomEmptyCard(
                          margin: const EdgeInsets.only(right: 10, bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            child: Column(
                              children: [
                                const Text("Pesanan Baru", style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                _loadingRekap
                                    ? const SizedBox(width: 24, height: 16, child: LinearProgressIndicator())
                                    : Text("$pesananBaru", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PesananPage(initialFilter: 'Disiapkan'),
                            ),
                          );
                        },
                        child: CustomEmptyCard(
                          margin: const EdgeInsets.only(left: 10, bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            child: Column(
                              children: [
                                const Text("Sedang Disiapkan", style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                _loadingRekap
                                    ? const SizedBox(width: 24, height: 16, child: LinearProgressIndicator())
                                    : Text("$sedangDisiapkan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ROW 2: Pickup & Diantar
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PesananPage(initialFilter: 'Pickup'),
                            ),
                          );
                        },
                        child: CustomEmptyCard(
                          margin: const EdgeInsets.only(right: 10, bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            child: Column(
                              children: [
                                const Text("Self Pickup", style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                _loadingRekap
                                    ? const SizedBox(width: 24, height: 16, child: LinearProgressIndicator())
                                    : Text("$selfPickup", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PesananPage(initialFilter: 'Diantar'),
                            ),
                          );
                        },
                        child: CustomEmptyCard(
                          margin: const EdgeInsets.only(left: 10, bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            child: Column(
                              children: [
                                const Text("Pesan Antar", style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                _loadingRekap
                                    ? const SizedBox(width: 24, height: 16, child: LinearProgressIndicator())
                                    : Text("$pesananAntar", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // MENU
                const Text("Akun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline, color: Colors.black),
                  title: const Text("Profil penjual"),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilSellerPage()));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book, color: Colors.black),
                  title: const Text("Menu Gerai"),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuRestoPage()));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_border, color: Colors.black),
                  title: const Text("Ulasan"),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UlasanPage()));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.store_mall_directory, color: Colors.black),
                  title: const Text("Kelola Gerai"),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KelolaProfilGeraiPage()));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Color(0xFFD53D3D)),
                  title: const Text("Keluar", style: TextStyle(color: Color(0xFFD53D3D), fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await logout(context);
                  },
                ),

                const SizedBox(height: 60), // for bottom nav space
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFF9D3D3).withOpacity(0.85),
          selectedItemColor: const Color(0xFFD53D3D),
          unselectedItemColor: Colors.black54,
          currentIndex: 0, // beranda
          onTap: (i) {
            if (i == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PesananPage(initialFilter: 'Konfirmasi Ketersediaan'),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Pesanan"),
          ],
        ),
      ),
    );
  }
}
