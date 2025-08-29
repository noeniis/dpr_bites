import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../common/utils/base_url.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';

class RekapPesananSellerPage extends StatefulWidget {
  const RekapPesananSellerPage({super.key});

  @override
  State<RekapPesananSellerPage> createState() => _RekapPesananSellerPageState();
}

class _RekapPesananSellerPageState extends State<RekapPesananSellerPage> {
  bool _isDataKosong() {
    if (statusCount.isEmpty) return true;
    return statusCount.values.every((v) => v == 0);
  }
  DateTime? _selectedDate;
  DateTime? _selectedMonth;
  bool _loading = true;
  Map<String, int> statusCount = {};
  int totalSaldo = 0;
  String? _idGerai;
  String? _error;
  bool _isMonthly = false;
  List<Map<String, dynamic>> menuRekap = [];
  List<Map<String, dynamic>> addonRekap = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchIdGeraiAndRekap();
  }

  Future<void> _fetchIdGeraiAndRekap() async {
    final prefs = await SharedPreferences.getInstance();
    final idGerai = prefs.getString('id_gerai');
    if (idGerai == null) {
      setState(() { _error = 'ID Gerai tidak ditemukan'; _loading = false; });
      return;
    }
    setState(() { _idGerai = idGerai; });
    await _fetchRekap();
  }

  Future<void> _fetchRekap() async {
    if (_idGerai == null) return;
    setState(() { _loading = true; _error = null; });
    final date = _selectedDate ?? DateTime.now();
    final tanggal = "${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    final uri = Uri.parse('${getBaseUrl()}/get_rekap_pesanan_seller.php')
        .replace(queryParameters: {'id_gerai': _idGerai!, 'tanggal': tanggal});
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            statusCount = Map<String, int>.from(data['debug_status_breakdown'] ?? {});
            totalSaldo = (data['total_saldo'] ?? 0) as int;
            menuRekap = (data['menu_rekap'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            addonRekap = (data['addon_rekap'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            _loading = false;
          });
        } else {
          setState(() { _error = data['message'] ?? 'Gagal memuat data'; _loading = false; });
        }
      } else {
        setState(() { _error = 'Gagal memuat data'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Belum ada data'; _loading = false; });
    }
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
      setState(() { _selectedDate = picked; });
      await _fetchRekap();
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    DateTime initial = _selectedMonth ?? DateTime(now.year, now.month);
    DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2, 1),
      lastDate: DateTime(now.year + 1, 12),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
        _isMonthly = true;
      });
      await _fetchRekapBulan();
    }
  }

  Future<void> _fetchRekapBulan() async {
    if (_idGerai == null || _selectedMonth == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final bulanStr =
        "${_selectedMonth!.year.toString().padLeft(4, '0')}-${_selectedMonth!.month.toString().padLeft(2, '0')}";

    final uri = Uri.parse('${getBaseUrl()}/get_rekap_pesanan_seller.php')
        .replace(queryParameters: {
      'id_gerai': _idGerai!,
      'tanggal': bulanStr, // kirim bulan ke backend
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            statusCount = {
              'pesanan_baru': data['pesanan_baru'] ?? 0,
              'sedang_disiapkan': data['sedang_disiapkan'] ?? 0,
              'diantar': data['diantar'] ?? 0,
              'pickup': data['pickup'] ?? 0,
              'selesai': data['debug_status_breakdown']?['selesai'] ?? 0,
              'dibatalkan': data['debug_status_breakdown']?['dibatalkan'] ?? 0,
            };
            totalSaldo = data['total_saldo'] ?? 0;
            menuRekap = (data['menu_rekap'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            addonRekap = (data['addon_rekap'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'Rekap gagal dimuat';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Gagal memuat data (status ${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final statusLabels = {
      'konfirmasi_ketersediaan': 'Konfirmasi Ketersediaan',
      'konfirmasi_pembayaran': 'Konfirmasi Pembayaran',
      'disiapkan': 'Disiapkan',
      'diantar': 'Diantar',
      'pickup': 'Pickup',
      'selesai': 'Selesai',
      'dibatalkan': 'Dibatalkan',
    };
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Rekap Pesanan Seller'),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          elevation: 1,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          setState(() { _isMonthly = false; });
                          await _pickDate();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryColor, width: 1.2),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                !_isMonthly
                                    ? (_selectedDate == null
                                        ? "Pilih Tanggal"
                                        : DateFormat('dd-MM-yyyy').format(_selectedDate!))
                                    : (_selectedMonth == null
                                        ? "Pilih Bulan"
                                        : DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth!)),
                                style: const TextStyle(fontSize: 14, color: AppTheme.textColor, fontWeight: FontWeight.w500),
                              ),
                              const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      ),
                      onPressed: () async {
                        await _pickMonth();
                      },
                      child: const Text('Rekap Bulan'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                        : _isDataKosong()
                            ? Center(
                                child: Text(
                                  _isMonthly
                                      ? 'Belum ada transaksi di bulan ini.'
                                      : 'Belum ada transaksi di tanggal ini.',
                                  style: const TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              )
                              
                            : Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Rekap Status
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isMonthly ? 'Rekap Status Pesanan Bulan Ini' : 'Rekap Status Pesanan',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 10),
                                            Table(
                                              border: TableBorder.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                              columnWidths: const {
                                                0: FlexColumnWidth(2),
                                                1: FlexColumnWidth(1),
                                              },
                                              children: [
                                                const TableRow(
                                                  decoration: BoxDecoration(color: Color(0xFFF9D3D3)),
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 8),
                                                      child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 8),
                                                      child: Center(child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    ),
                                                  ],
                                                ),
                                                ...statusLabels.entries.map((e) => TableRow(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                          child: Text(e.value),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                          child: Center(
                                                            child: Text(
                                                              statusCount[e.key]?.toString() ?? '0',
                                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      // Rekap Menu Terjual
                                      if (menuRekap.isNotEmpty) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          margin: const EdgeInsets.only(bottom: 18),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.03),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Menu Terjual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 10),
                                              Table(
                                                border: TableBorder.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                                columnWidths: const {
                                                  0: FlexColumnWidth(3),
                                                  1: FlexColumnWidth(1),
                                                },
                                                children: [
                                                  const TableRow(
                                                    decoration: BoxDecoration(color: Color(0xFFE3F2FD)),
                                                    children: [
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8),
                                                        child: Center(child: Text('Nama Menu', style: TextStyle(fontWeight: FontWeight.bold))),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8),
                                                        child: Center(child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                                                      ),
                                                    ],
                                                  ),
                                                  ...menuRekap.map((m) => TableRow(
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Text(m['nama_menu'] ?? '-'),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Center(child: Text(m['total_terjual']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold))),
                                                          ),
                                                        ],
                                                      )),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      // Rekap Add-on Terjual
                                      if (addonRekap.isNotEmpty) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          margin: const EdgeInsets.only(bottom: 18),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.03),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Add-on Terjual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 10),
                                              Table(
                                                border: TableBorder.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                                columnWidths: const {
                                                  0: FlexColumnWidth(3),
                                                  1: FlexColumnWidth(1),
                                                },
                                                children: [
                                                  const TableRow(
                                                    decoration: BoxDecoration(color: Color(0xFFFFF9C4)),
                                                    children: [
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8),
                                                        child: Center(child: Text('Nama Add-on', style: TextStyle(fontWeight: FontWeight.bold))),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8),
                                                        child: Center(child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                                                      ),
                                                    ],
                                                  ),
                                                  ...addonRekap.map((a) => TableRow(
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Text(a['nama_addon'] ?? '-'),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Center(child: Text(a['total_terjual']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold))),
                                                          ),
                                                        ],
                                                      )),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      // Total Pendapatan
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isMonthly ? 'Total Pendapatan Bulan Ini' : 'Total Pendapatan',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Rp ${NumberFormat('#,###', 'id_ID').format(totalSaldo)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.primaryColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
