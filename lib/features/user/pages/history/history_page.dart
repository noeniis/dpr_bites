import 'package:dpr_bites/features/user/pages/history/receipt_page.dart';
import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
// import 'package:dpr_bites/common/data/dummy_orders.dart'; // replaced by live API
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/favorit/favorit.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';

class HistoryPage extends StatefulWidget {
  final String? initialFilter;
  const HistoryPage({super.key, this.initialFilter});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late String filter;
  final int _userId = 1; // TODO: ganti dengan user id dari auth
  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;
  String? _error;

  static const _progressStatuses = [
    'konfirmasi_ketersediaan',
    'konfirmasi_pembayaran',
    'disiapkan',
    'diantar',
    'pickup',
  ];

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_user_transactions.php?user_id=$_userId',
      );
      final resp = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final j = jsonDecode(resp.body);
      if (j is! Map || j['success'] != true)
        throw Exception(
          j is Map ? (j['message'] ?? 'Gagal') : 'Respon tidak valid',
        );
      final data = j['data'];
      if (data is List) {
        _orders = data
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    return _orders.where((o) {
      final status = (o['status'] ?? '').toString();
      if (filter == 'berlangsung') return _progressStatuses.contains(status);
      if (filter == 'selesai') return status == 'selesai';
      return status == 'dibatalkan';
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    filter = widget.initialFilter ?? 'berlangsung';
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFB03056)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              : null,
          title: const Text(
            'Riwayat Pemesanan',
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomFilterChip(
                        label: 'Berlangsung',
                        selected: filter == 'berlangsung',
                        onTap: () => setState(() => filter = 'berlangsung'),
                      ),
                      const SizedBox(width: 12),
                      CustomFilterChip(
                        label: 'Selesai',
                        selected: filter == 'selesai',
                        onTap: () => setState(() => filter = 'selesai'),
                      ),
                      const SizedBox(width: 12),
                      CustomFilterChip(
                        label: 'Dibatalkan',
                        selected: filter == 'dibatalkan',
                        onTap: () => setState(() => filter = 'dibatalkan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredOrders.isEmpty
                    ? Center(
                        child: Text(
                          _error != null
                              ? 'Error: $_error'
                              : 'Tidak ada riwayat pesanan.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 23),
                        itemBuilder: (context, idx) {
                          final order = filteredOrders[idx];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4E6ED),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    order['icon'] ??
                                        'lib/assets/images/spatulaknife.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            order['restaurantName'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 90,
                                          child: Text(
                                            order['price'] != null
                                                ? 'Rp${order['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
                                                : '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Tanggal pemesanan di bawah nama warung
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        order['dateDisplay'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReceiptPage(order: order),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            'Lihat Struk Pemesanan',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFFB03056),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward,
                                            size: 16,
                                            color: Color(0xFFB03056),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFF9D3D3).withOpacity(0.85),
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.black54,
          currentIndex: 1,
          selectedFontSize: 14,
          unselectedFontSize: 13,
          iconSize: 30,
          onTap: (i) {
            if (i == 0) {
              // Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            } else if (i == 1) {
              // History
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            } else if (i == 2) {
              // Favorit
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FavoritPage()),
              );
            } else if (i == 3) {
              // Profile
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: "Favorit",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }
}
