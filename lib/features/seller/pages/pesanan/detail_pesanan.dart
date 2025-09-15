import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dpr_bites/features/seller/models/pesanan/order_api_model.dart';
import 'package:dpr_bites/features/seller/models/pesanan/transaction_detail_model.dart';
import 'package:dpr_bites/features/seller/services/transaction_detail_service.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'delivery_map_page.dart';
class DetailPesananPage extends StatefulWidget {
  final OrderApiModel order;

  const DetailPesananPage({super.key, required this.order});

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  File? _buktiPembayaranFile;
  bool _isUploadingBukti = false;
  Widget _buildActionButtons(TransactionDetailModel detail) {
    final status = detail.status.toLowerCase();
      switch (status) {
    case 'konfirmasi_ketersediaan':
      return Column(
        children: [
          // === TERIMA PESANAN ===
          SizedBox(
            width: double.infinity,
            child: CustomButtonKotak(
              text: 'Terima Pesanan',
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  final idTransaksi = detail.idTransaksi;
                  final isCash = detail.metodePembayaran.toLowerCase().trim() == 'cash';
                  final nextStatus = isCash ? 'disiapkan' : 'konfirmasi_pembayaran';
                  final stokSuccess = await TransactionDetailService.confirmAvailability(
                    idTransaksi: idTransaksi,
                    available: true,
                  );
                  if (stokSuccess) {
                    final statusSuccess = await TransactionDetailService.updateStatus(
                      idTransaksi: idTransaksi,
                      newStatus: nextStatus,
                    );
                    Navigator.of(context, rootNavigator: true).pop(); // close loading
                    if (statusSuccess) {
                      Navigator.pop(context, {'status': nextStatus});
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Gagal'),
                          content: const Text('Stok terupdate, tapi gagal update status pesanan.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                          ],
                        ),
                      );
                    }
                  } else {
                    Navigator.of(context, rootNavigator: true).pop();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Gagal'),
                        content: const Text('Gagal update stok/menu. Coba lagi.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(context, rootNavigator: true).pop();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: Text('Terjadi error: $e'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // === TOLAK PESANAN ===
          SizedBox(
            width: double.infinity,
            child: CustomButtonKotak(
              text: 'Tolak Pesanan',
              backgroundColor: const Color(0xFF9E9595),
              onPressed: () async {
                String? alasan = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    String? selectedReason;
                    TextEditingController alasanController = TextEditingController();
                    String? errorText;

                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Alasan Penolakan'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedReason,
                                hint: const Text('Pilih alasan'),
                                items: const [
                                  DropdownMenuItem(value: 'Stok kosong', child: Text('Stok kosong')),
                                  DropdownMenuItem(value: 'Menu habis', child: Text('Menu habis')),
                                  DropdownMenuItem(value: 'Toko tutup', child: Text('Toko tutup')),
                                  DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    selectedReason = val;
                                    if (val != 'Lainnya') {
                                      alasanController.text = val ?? '';
                                    } else {
                                      alasanController.text = '';
                                    }
                                    errorText = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: alasanController,
                                enabled: selectedReason == 'Lainnya',
                                decoration: InputDecoration(
                                  hintText: 'Alasan',
                                  errorText: errorText,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final alasanFinal = alasanController.text.isNotEmpty
                                    ? alasanController.text
                                    : selectedReason;
                                if (alasanFinal == null || alasanFinal.isEmpty) {
                                  setState(() {
                                    errorText = 'Alasan wajib diisi';
                                  });
                                  return;
                                }
                                Navigator.pop(context, alasanFinal);
                              },
                              child: const Text('Kirim'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (alasan != null && alasan.isNotEmpty) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    final idTransaksi = detail.idTransaksi;
                    final rejectSuccess = await TransactionDetailService.confirmAvailability(
                      idTransaksi: idTransaksi,
                      available: false,
                      alasan: alasan,
                    );
                    Navigator.of(context, rootNavigator: true).pop(); // close loading
                    if (rejectSuccess) {
                      Navigator.pop(context, {'status': 'canceled', 'alasan': alasan});
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Gagal'),
                          content: const Text('Gagal menolak pesanan. Coba lagi.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.of(context, rootNavigator: true).pop();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Error'),
                        content: Text('Terjadi error: $e'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      );
      case 'konfirmasi_pembayaran':
        return Column(
          children: [
            if (detail.buktiPembayaran != null && detail.buktiPembayaran!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: CustomButtonKotak(
                  text: 'Lihat Bukti Pembayaran',
                  backgroundColor: const Color(0xFF4A90E2),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Bukti Pembayaran'),
                        content: SizedBox(
                          width: 300,
                          child: Image.network(
                            detail.buktiPembayaran!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Text('Gagal memuat gambar'),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButtonKotak(
                text: 'Konfirmasi Pembayaran',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: const Text('Yakin ingin mengkonfirmasi pembayaran?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Ya'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );
                    try {
                      final idTransaksi = detail.idTransaksi;
                      final resp = await TransactionDetailService.updateStatusRaw(
                        idTransaksi: idTransaksi,
                        newStatus: "disiapkan",
                      );
                      Navigator.of(context, rootNavigator: true).pop(); // close loading
                      final statusCode = resp['statusCode'] as int? ?? 0;
                      final body = resp['body'] as String? ?? '';
                      final success = statusCode == 200 && body.contains('success');
                      if (success) {
                        Navigator.pop(context, {'status': 'disiapkan'});
                      } else {
                        String message = 'Gagal mengubah status pesanan. Coba lagi.';
                        try {
                          final parsed = body.isNotEmpty ? jsonDecode(body) : null;
                          if (parsed is Map && parsed['message'] != null) message = parsed['message'];
                        } catch (_) {}
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Gagal'),
                            content: Text(message),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.of(context, rootNavigator: true).pop();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: Text('Terjadi error: $e'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        );
      case 'disiapkan':
        return SizedBox(
          width: double.infinity,
          child: CustomButtonKotak(
            text: 'Selesai Disiapkan',
            onPressed: () async {
              final nextStatus = detail.jenisPengantaran == 'pengantaran' ? 'diantar' : 'pickup';
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              try {
                final idTransaksi = detail.idTransaksi;
                final statusSuccess = await TransactionDetailService.updateStatus(
                  idTransaksi: idTransaksi,
                  newStatus: nextStatus,
                );
                Navigator.of(context, rootNavigator: true).pop();
                if (statusSuccess) {
                  Navigator.pop(context, {'status': nextStatus});
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Gagal'),
                      content: Text('Gagal mengubah status pesanan. Coba lagi.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                    ),
                  );
                }
              } catch (e) {
                Navigator.of(context, rootNavigator: true).pop();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: Text('Terjadi error: $e'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  ),
                );
              }
            },
          ),
        );
      case 'diantar':
        return Column(
          children: [
            if (detail.metodePembayaran.toLowerCase().trim() == 'cash') ...[
              if (_buktiPembayaranFile != null || (detail.buktiPembayaran != null && detail.buktiPembayaran!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, color: Color(0xFF4A90E2), size: 32),
                        tooltip: 'Lihat Bukti Pembayaran',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Bukti Pembayaran'),
                              content: SizedBox(
                                width: 300,
                                child: detail.buktiPembayaran != null && detail.buktiPembayaran!.isNotEmpty
                                    ? Image.network(
                                        detail.buktiPembayaran!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Text('Gagal memuat gambar'),
                                      )
                                    : Image.file(_buktiPembayaranFile!, fit: BoxFit.contain),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text('Bukti pembayaran terupload', style: TextStyle(fontSize: 14, color: Color(0xFF50555C))),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: CustomButtonKotak(
                  text: _isUploadingBukti
                      ? 'Mengupload...'
                      : (_buktiPembayaranFile == null ? 'Upload Bukti Pembayaran' : 'Ganti Bukti Pembayaran'),
                  backgroundColor: Color(0xFF4A90E2),
                  onPressed: _isUploadingBukti
                      ? null
                      : () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() { _buktiPembayaranFile = File(picked.path); });
                          }
                        },
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: CustomButtonKotak(
                text: 'Selesai Diantar',
                onPressed: (detail.metodePembayaran.toLowerCase().trim() == 'cash' && _buktiPembayaranFile == null && (detail.buktiPembayaran == null || detail.buktiPembayaran!.isEmpty))
                    ? null
                    : () async {
                        if (detail.metodePembayaran.toLowerCase().trim() == 'cash') {
                          // Upload bukti pembayaran jika file dipilih dan belum pernah upload
                          if (_buktiPembayaranFile != null && (detail.buktiPembayaran == null || detail.buktiPembayaran!.isEmpty)) {
                            setState(() { _isUploadingBukti = true; });
                            try {
                              final uploadSuccess = await TransactionDetailService.uploadBuktiPembayaran(
                                idTransaksi: detail.idTransaksi,
                                filePath: _buktiPembayaranFile!.path,
                              );
                              if (uploadSuccess) {
                                final statusSuccess = await TransactionDetailService.updateStatus(
                                  idTransaksi: detail.idTransaksi,
                                  newStatus: "selesai",
                                );
                                if (statusSuccess) {
                                  await fetchDetail();
                                  Navigator.pop(context, {'status': 'selesai'});
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Gagal update status ke selesai')),);
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Upload bukti pembayaran gagal, coba lagi')),);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              setState(() { _isUploadingBukti = false; });
                            }
                          } else if (detail.buktiPembayaran != null && detail.buktiPembayaran!.isNotEmpty) {
                            // Sudah ada bukti, langsung update status
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              final statusSuccess = await TransactionDetailService.updateStatus(
                                idTransaksi: detail.idTransaksi,
                                newStatus: "selesai",
                              );
                              Navigator.of(context, rootNavigator: true).pop();
                              if (statusSuccess) {
                                await fetchDetail();
                                Navigator.pop(context, {'status': 'selesai'});
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Gagal'),
                                    content: Text('Gagal update status ke selesai'),
                                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                                  ),
                                );
                              }
                            } catch (e) {
                              Navigator.of(context, rootNavigator: true).pop();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Error'),
                                  content: Text('Terjadi error: $e'),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                                ),
                              );
                            }
                          }
                        } else {
                          // Non-cash: langsung update status ke selesai
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          try {
                            final statusSuccess = await TransactionDetailService.updateStatus(
                              idTransaksi: detail.idTransaksi,
                              newStatus: "selesai",
                            );
                            Navigator.of(context, rootNavigator: true).pop();
                            if (statusSuccess) {
                              await fetchDetail();
                              Navigator.pop(context, {'status': 'selesai'});
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Gagal'),
                                  content: Text('Gagal update status ke selesai'),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.of(context, rootNavigator: true).pop();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Error'),
                                content: Text('Terjadi error: $e'),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                              ),
                            );
                          }
                        }
                      },
              ),
            ),
          ],
        );
      case 'pickup':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: CustomButtonKotak(
                text: 'Selesai Pick Up',
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    final statusSuccess = await TransactionDetailService.updateStatus(
                      idTransaksi: detail.idTransaksi,
                      newStatus: "selesai",
                    );
                    Navigator.of(context, rootNavigator: true).pop();
                    if (statusSuccess) {
                      await fetchDetail();
                      Navigator.pop(context, {'status': 'selesai'});
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Gagal'),
                          content: Text('Gagal update status ke selesai'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.of(context, rootNavigator: true).pop();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Error'),
                        content: Text('Terjadi error: $e'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            ),
          ],
        );
      case 'selesai':
      case 'dibatalkan':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
  // Method untuk menghitung total harga pesanan (item + addon + ongkir jika ada)
  int hitungTotalHarga(TransactionDetailModel detail) {
    int total = 0;
    for (final item in detail.items) {
      total += item.harga * item.jumlah;
      for (final addon in item.addons) {
        total += addon.harga * item.jumlah;
      }
    }
    if (detail.jenisPengantaran == 'pengantaran') {
      total += 5000;
    }
    return total;
  }
  TransactionDetailModel? detail;
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    setState(() { isLoading = true; errorMsg = null; });
    try {
      final res = await TransactionDetailModel.fetchByBookingId(widget.order.bookingId);
      if (!mounted) return;
      if (res != null) {
        setState(() { detail = res; isLoading = false; });
      } else {
        setState(() { errorMsg = 'Data pesanan tidak ditemukan.'; isLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { errorMsg = 'Gagal memuat detail: $e'; isLoading = false; });
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFD53D3D), size: 28),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMsg != null
                  ? Center(child: Text(errorMsg!, style: const TextStyle(color: Colors.red)))
                  : detail == null
                      ? const Center(child: Text('Data tidak ditemukan'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomEmptyCard(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pesanan untuk ${widget.order.namaPemesan}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF602829),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Booking ID: ${widget.order.bookingId}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF50555C),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        detail!.jenisPengantaran == 'pengantaran' ? 'Pesan Antar' : 'Ambil Sendiri',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF602829),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (detail!.jenisPengantaran == 'pengantaran')
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 20, color: Colors.black),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: (detail!.alamatPengantaranLat != null && detail!.alamatPengantaranLng != null)
                                                    ? () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => DeliveryMapPage(
                                                              lat: detail!.alamatPengantaranLat!,
                                                              lng: detail!.alamatPengantaranLng!,
                                                              address: detail!.alamatPengantaranDetail,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    : null,
                                                child: Text(
                                                  detail!.alamatPengantaranDetail ?? '-',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: (detail!.alamatPengantaranLat != null && detail!.alamatPengantaranLng != null)
                                                        ? Color(0xFF4A90E2)
                                                        : Color(0xFF50555C),
                                                    decoration: (detail!.alamatPengantaranLat != null && detail!.alamatPengantaranLng != null)
                                                        ? TextDecoration.underline
                                                        : TextDecoration.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 16),
                                      // Header row detail
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: const [
                                            Expanded(child: Text('Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                            SizedBox(width: 12),
                                            Text('Harga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            SizedBox(width: 12),
                                            Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 18),
                                      ...detail!.items.map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 7),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${item.jumlah} × ${item.namaMenu}',
                                                      style: const TextStyle(fontSize: 16, color: Color(0xFF602829)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  SizedBox(
                                                    width: 80,
                                                    child: Text(
                                                      'Rp ${item.harga}',
                                                      style: const TextStyle(fontSize: 16, color: Color(0xB51E1E1E)),
                                                      textAlign: TextAlign.right,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  SizedBox(
                                                    width: 90,
                                                    child: Text(
                                                      'Rp ${(item.harga * item.jumlah)}',
                                                      style: const TextStyle(fontSize: 16, color: Color(0xB51E1E1E)),
                                                      textAlign: TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Tampilkan note jika ada
                                              if (item.note != null && item.note.toString().trim().isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                                                  child: Text(
                                                    'Catatan: ${item.note}',
                                                    style: const TextStyle(fontSize: 13, color: Color(0xFF4A90E2), fontStyle: FontStyle.italic),
                                                  ),
                                                ),
                                              // Tampilkan addon jika ada
                                              if (item.addons.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 16.0, top: 2, bottom: 2),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      ...item.addons.map((addon) => Row(
                                                        children: [
                                                          const Text('↳ ', style: TextStyle(fontSize: 13, color: Color(0xFF50555C))),
                                                          Expanded(
                                                            child: Text(
                                                              addon.namaAddon,
                                                              style: const TextStyle(fontSize: 13, color: Color(0xFF50555C)),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 80,
                                                            child: Text(
                                                              'Rp ${addon.harga}',
                                                              style: const TextStyle(fontSize: 13, color: Color(0xB51E1E1E)),
                                                              textAlign: TextAlign.right,
                                                            ),
                                                          ),
                                                        ],
                                                      )),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Ongkir hanya jika pengantaran
                                      if (detail!.jenisPengantaran == 'pengantaran')
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: const [
                                            Text('Ongkir', style: TextStyle(fontSize: 15, color: Color(0xFF602829))),
                                            Text('Rp 5000', style: TextStyle(fontSize: 15, color: Color(0xFF602829))),
                                          ],
                                        ),
                                      if (detail!.jenisPengantaran == 'pengantaran')
                                        const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Harga Total',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF602829)),
                                          ),
                                          Text(
                                            'Rp ${hitungTotalHarga(detail!)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD53D3D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const SizedBox(height: 30),
                              if (detail != null)
                                Center(
                                  child: _buildActionButtons(detail!),
                                ),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }
}
