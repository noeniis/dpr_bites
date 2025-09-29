import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:dpr_bites/features/seller/services/rekap_pesanan_service.dart';
import 'package:dpr_bites/features/seller/models/rekap_pesanan_model.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';

class RekapPesananSellerPage extends StatefulWidget {
  const RekapPesananSellerPage({super.key});

  @override
  State<RekapPesananSellerPage> createState() => _RekapPesananSellerPageState();
}

class _RekapPesananSellerPageState extends State<RekapPesananSellerPage> {
  RekapPesananModel? _rekapModel;
  bool _isDataKosong() {
    if (_rekapModel == null || _rekapModel!.statusCount.isEmpty) return true;
    return _rekapModel!.statusCount.values.every((v) => v == 0);
  }
  DateTime? _selectedDate;
  DateTime? _selectedMonth;
  bool _loading = true;
  String? _idGerai;
  String? _error;
  bool _isMonthly = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchIdGeraiAndRekap();
  }

  Future<void> _fetchIdGeraiAndRekap() async {
    final storage = FlutterSecureStorage();
    final idGerai = await storage.read(key: 'id_gerai');
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
    try {
      final rekap = await RekapPesananService.fetchRekap(idGerai: _idGerai!, tanggal: tanggal);
      setState(() {
        _rekapModel = rekap;
        _loading = false;
        _error = rekap == null ? 'Belum ada data' : null;
      });
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
    final bulanStr = "${_selectedMonth!.year.toString().padLeft(4, '0')}-${_selectedMonth!.month.toString().padLeft(2, '0')}";
    try {
      final rekap = await RekapPesananService.fetchRekap(idGerai: _idGerai!, tanggal: bulanStr);
      setState(() {
        _rekapModel = rekap;
        _loading = false;
        _error = rekap == null ? 'Belum Ada Data' : null;
      });
    } catch (e) {
      setState(() {
        _error = 'Belum Ada Data';
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
                                                              _rekapModel?.statusCount[e.key]?.toString() ?? '0',
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
                                      if (_rekapModel?.menuRekap.isNotEmpty ?? false) ...[
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
                                                0: FlexColumnWidth(2),
                                                1: FlexColumnWidth(1),
                                                2: FlexColumnWidth(1.2),
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
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8),
                                                        child: Center(child: Text('Pendapatan', style: TextStyle(fontWeight: FontWeight.bold))),
                                                      ),
                                                    ],
                                                  ),
                                                  ...?_rekapModel?.menuRekap.map((m) => TableRow(
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Text(m['nama_menu'] ?? '-'),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Center(child: Text(m['total_terjual']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold))),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Center(child: Text('Rp ${NumberFormat('#,###', 'id_ID').format(m['total_pendapatan'] ?? ( (m['harga_satuan'] ?? 0) * (m['total_terjual'] ?? 0) ))}', style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                      if (_rekapModel?.addonRekap.isNotEmpty ?? false) ...[
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
                                                  0: FlexColumnWidth(2),
                                                  1: FlexColumnWidth(1),
                                                  2: FlexColumnWidth(1.2),
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
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8),
                                                        child: Center(child: Text('Pendapatan', style: TextStyle(fontWeight: FontWeight.bold))),
                                                      ),
                                                    ],
                                                  ),
                                                  ...?_rekapModel?.addonRekap.map((a) => TableRow(
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Text(a['nama_addon'] ?? '-'),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Center(child: Text(a['total_terjual']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold))),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Center(child: Text('Rp ${NumberFormat('#,###', 'id_ID').format(a['total_pendapatan'] ?? ( (a['harga'] ?? 0) * (a['total_terjual'] ?? 0) ))}', style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                              'Rp ${NumberFormat('#,###', 'id_ID').format(_rekapModel?.totalSaldo ?? 0)}',
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
