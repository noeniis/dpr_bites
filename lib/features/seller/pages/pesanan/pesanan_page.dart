import 'package:flutter/material.dart';
import 'package:dpr_bites/models/order_model.dart';
import 'package:dpr_bites/common/data/dummy_pesanan.dart';
import 'siap_diantar_page.dart'; // Halaman untuk siap diantar
import 'pesanan_selesai_page.dart'; // Halaman untuk pesanan selesai
import 'terima_pesanan_page.dart';
import 'package:dpr_bites/features/seller/pages/beranda/dashboard_page.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';

class PesananPage extends StatefulWidget {
  const PesananPage({super.key});

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  late List<OrderModel> pesananList;
  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Masuk',
    'Diterima',
    'Ditolak',
    'Disiapkan',
    'Diantar',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    pesananList = dummyPesanan.map((order) {
      // Pastikan status selalu ada
      if (order.status == '') {
        order.status = '';
      }
      return order;
    }).toList();
  }

  List<OrderModel> get filteredPesananList {
    if (_selectedFilter == 'Semua') return pesananList;
    switch (_selectedFilter) {
      case 'Masuk':
        return pesananList.where((p) => p.status == '').toList();
      case 'Diterima':
        return pesananList.where((p) => p.status == 'sedang disiapkan').toList();
      case 'Ditolak':
        return pesananList.where((p) => p.status == 'order cancel').toList();
      case 'Disiapkan':
        return pesananList.where((p) => p.status == 'sedang disiapkan').toList();
      case 'Diantar':
        return pesananList.where((p) => p.status == 'pesanan diantar').toList();
      case 'Selesai':
        return pesananList.where((p) => p.status == 'pesanan selesai').toList();
      default:
        return pesananList;
    }
  }

  void _navigateToTerimaPesanan(OrderModel pesanan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TerimaPesananPage(order: pesanan),
      ),
    );

    if (result == 'accepted') {
      setState(() {
        pesanan.status = 'sedang disiapkan';
      });
    } else if (result is Map && result['status'] == 'canceled') {
      setState(() {
        pesanan.status = 'order cancel';
        pesanan.keterangan = result['alasan'] ?? '';
      });
    } else if (result == 'delivered') {
      setState(() {
        pesanan.status = 'pesanan diantar';
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
          leading: const Icon(Icons.list_alt, color: Color(0xFFD53D3D), size: 28),
          title: const Text(
            'Pesanan Masuk',
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFD53D3D)),
              tooltip: 'Reset pesanan',
              onPressed: () {
                setState(() {
                  for (var pesanan in pesananList) {
                    if (pesanan.status != 'order cancel') {
                      pesanan.status = '';
                    }
                  }
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Filter horizontal scrollable
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: List.generate(_filters.length, (i) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CustomFilterChipKotak(
                      label: _filters[i],
                      selected: _selectedFilter == _filters[i],
                      onTap: () => setState(() => _selectedFilter = _filters[i]),
                    ),
                  )),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredPesananList.length,
                  itemBuilder: (context, index) {
                    final pesanan = filteredPesananList[index];
                    return CustomEmptyCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pesanan.jumlahPesanan} Pesanan untuk ${pesanan.namaPemesan}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF602829),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Booking ID: ${pesanan.bookingId}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF50555C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: pesanan.status == 'order cancel'
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE57373),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: const Text(
                                            'Pesanan Dibatalkan',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if ((pesanan.keterangan ?? '').isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              'Alasan: ${pesanan.keterangan}',
                                              style: const TextStyle(fontSize: 13, color: Colors.red),
                                            ),
                                          ),
                                      ],
                                    )
                                  : ElevatedButton(
                                      onPressed: (pesanan.status == 'pesanan selesai')
                                          ? null
                                          : () {
                                              if (pesanan.status == 'sedang disiapkan') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => SiapDiantarPage(order: pesanan),
                                                  ),
                                                ).then((result) {
                                                  if (result == 'delivered') {
                                                    setState(() {
                                                      pesanan.status = 'pesanan diantar';
                                                    });
                                                  }
                                                });
                                              } else if (pesanan.status == 'pesanan diantar') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => PesananSelesaiPage(order: pesanan),
                                                  ),
                                                ).then((result) {
                                                  if (result == 'completed') {
                                                    setState(() {
                                                      pesanan.status = 'pesanan selesai';
                                                    });
                                                  }
                                                });
                                              } else {
                                                _navigateToTerimaPesanan(pesanan);
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: pesanan.status == 'sedang disiapkan'
                                            ? const Color(0xFFD9F0D2)
                                            : pesanan.status == 'pesanan diantar'
                                                ? const Color(0xFFD3E3F9)
                                                : pesanan.status == 'pesanan selesai'
                                                    ? const Color(0xFFBDBDBD)
                                                    : const Color(0xFFEFEFEF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        pesanan.status == 'sedang disiapkan'
                                            ? 'Sedang Disiapkan'
                                            : pesanan.status == 'pesanan diantar'
                                                ? 'Pesanan Diantar'
                                                : pesanan.status == 'pesanan selesai'
                                                    ? 'Pesanan Selesai'
                                                    : 'Cek Order',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: pesanan.status == 'sedang disiapkan'
                                              ? Colors.green[900]
                                              : pesanan.status == 'pesanan diantar'
                                                  ? Colors.blue[900]
                                                  : pesanan.status == 'pesanan selesai'
                                                      ? Colors.grey[600]
                                                      : Colors.black.withAlpha(214),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFF9D3D3).withOpacity(0.85),
          selectedItemColor: const Color(0xFFD53D3D),
          unselectedItemColor: Colors.black54,
          currentIndex: 1, // pesanan
          onTap: (i) {
            if (i == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SellerDashboardPage(),
                ),
              );
            }
            // Tab 1 (Pesanan) does nothing since already here
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Beranda",
            ),
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
