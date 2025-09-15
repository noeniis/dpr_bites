import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dpr_bites/features/seller/services/pesanan_service.dart';
import 'package:dpr_bites/features/seller/pages/beranda/dashboard_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/features/seller/models/pesanan/order_api_model.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/features/seller/pages/pesanan/detail_pesanan.dart';
import 'package:dpr_bites/app/gradient_background.dart';

class PesananPage extends StatefulWidget {
  final String? initialFilter;
  const PesananPage({Key? key, this.initialFilter}) : super(key: key);

  @override
  _PesananPageState createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  Timer? _refreshTimer;
  List<OrderApiModel> pesananList = [];
  bool isLoading = true;
  late String _selectedFilter;
  String? idGerai;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  DateTime? _selectedDate;

  final List<String> _filters = const [
    'Semua',
    'Konfirmasi Ketersediaan',
    'Konfirmasi Pembayaran',
    'Disiapkan',
    'Diantar',
    'Pickup',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'Semua';
    _selectedDate = DateTime.now();
    loadIdGeraiAndFetch();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && idGerai != null && idGerai!.isNotEmpty) {
        fetchPesanan();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadIdGeraiAndFetch() async {
    try {
      final id = await _secureStorage.read(key: 'id_gerai');

      if (!mounted) return;
      setState(() {
        idGerai = id;
      });

      if (idGerai == null || idGerai!.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      await fetchPesanan();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat id_gerai: $e')),
      );
    }
  }

  Future<void> fetchPesanan() async {
    if (idGerai == null || idGerai!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }
    setState(() => isLoading = true);
    try {
      final list = await PesananService.fetchPesanan(idGerai: idGerai!, tanggal: _selectedDate);
      if (!mounted) return;
      setState(() {
        pesananList = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        pesananList = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  List<OrderApiModel> get filteredPesananList {
    return PesananService.filterPesanan(pesananList, _selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    final showNoGerai = !isLoading && (idGerai == null || idGerai!.isEmpty);

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
              tooltip: 'Refresh pesanan',
              onPressed: fetchPesanan,
            ),
          ],
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : showNoGerai
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'id_gerai belum tersedia.\nSilakan login sebagai seller atau pilih gerai dulu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF50555C)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.settings),
                              label: const Text('Pergi ke Beranda Seller'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SellerDashboardPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Date picker di atas filter status
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.date_range, size: 18, color: Color(0xFFD53D3D)),
                                  label: Text(
                                    _selectedDate == null
                                        ? 'Filter Tanggal'
                                        : '${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}',
                                    style: const TextStyle(color: Color(0xFF602829)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFD53D3D)),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate ?? now,
                                      firstDate: DateTime(now.year - 2),
                                      lastDate: DateTime(now.year + 1),
                                      locale: const Locale('id', 'ID'),
                                    );
                                    if (picked != null) {
                                      setState(() { _selectedDate = picked; });
                                      fetchPesanan();
                                    }
                                  },
                                ),
                              ),
                              if (_selectedDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: Color(0xFFD53D3D)),
                                    tooltip: 'Hapus filter tanggal',
                                    onPressed: () {
                                      setState(() { _selectedDate = null; });
                                      fetchPesanan();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              ...List.generate(
                                _filters.length,
                                (i) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: CustomFilterChipKotak(
                                    label: _filters[i],
                                    selected: _selectedFilter == _filters[i],
                                    onTap: () => setState(() => _selectedFilter = _filters[i]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filteredPesananList.isEmpty
                              ? const Center(child: Text('Tidak ada pesanan'))
                              : ListView.builder(
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
                                              'Booking ID: ${pesanan.bookingId}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF602829),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Pemesan: ${pesanan.namaPemesan}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF50555C),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: pesanan.status == 'konfirmasi_ketersediaan'
                                                      ? const Color(0xFFEFEFEF)
                                                      : pesanan.status == 'konfirmasi_pembayaran'
                                                          ? Colors.yellow[200]
                                                          : pesanan.status == 'disiapkan'
                                                              ? Colors.green[200]
                                                              : pesanan.status == 'diantar'
                                                                  ? Colors.blue[200]
                                                                  : pesanan.status == 'pickup'
                                                                      ? Colors.purple[200]
                                                                      : pesanan.status == 'selesai'
                                                                          ? Colors.grey[400]
                                                                          : pesanan.status == 'dibatalkan'
                                                                              ? Colors.red[200]
                                                                              : const Color(0xFFEFEFEF),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  elevation: 2,
                                                ),
                                                onPressed: () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => DetailPesananPage(order: pesanan),
                                                    ),
                                                  );
                                                  if (result != null) {
                                                    fetchPesanan();
                                                  }
                                                },
                                                child: Text(
                                                  pesanan.status == 'konfirmasi_ketersediaan'
                                                      ? 'Cek Order'
                                                      : pesanan.status == 'konfirmasi_pembayaran'
                                                          ? 'Konfirmasi Pembayaran'
                                                          : pesanan.status == 'disiapkan'
                                                              ? 'Disiapkan'
                                                              : pesanan.status == 'diantar'
                                                                  ? 'Diantar'
                                                                  : pesanan.status == 'pickup'
                                                                      ? 'Pickup'
                                                                      : pesanan.status == 'selesai'
                                                                          ? 'Selesai'
                                                                          : pesanan.status == 'dibatalkan'
                                                                              ? 'Dibatalkan'
                                                                              : 'Cek Order',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: pesanan.status == 'dibatalkan'
                                                        ? Colors.red[900]
                                                        : pesanan.status == 'selesai'
                                                            ? Colors.grey[800]
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
          currentIndex: 1, 
          onTap: (i) {
            if (i == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerDashboardPage()),
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
