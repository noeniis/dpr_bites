import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
// import 'package:dpr_bites/common/data/dummy_orders.dart'; // replaced by live API
import 'package:dpr_bites/features/user/services/receipt_page_service.dart';
import 'package:dpr_bites/features/user/pages/checkout/checkout_process_page.dart';
import 'package:dpr_bites/features/user/pages/review/review_page.dart'; // contains ReviewSheetRoute
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptPage extends StatefulWidget {
  final Map<String, dynamic>? order; // optional preloaded
  final String? bookingId;
  final int? idTransaksi;
  const ReceiptPage({super.key, this.order, this.bookingId, this.idTransaksi});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;
  bool _hasReview = false;
  Map<String, dynamic>? _reviewData; // rating & komentar
  bool _reviewLoading = false;

  Future<void> _checkReview() async {
    try {
      if (_data == null) return;
      final idTrans = _data!['id_transaksi'];
      if (idTrans == null) return;
      _reviewLoading = true;
      if (mounted) setState(() {});
      final res = await ReceiptPageService.fetchReviewStatus(
        idTrans is int ? idTrans : int.tryParse(idTrans.toString()) ?? 0,
      );
      if (res.error == null) {
        _hasReview = res.hasReview;
        _reviewData = res.review;
      }
      if (mounted) setState(() {});
    } catch (_) {}
    _reviewLoading = false;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _data = Map<String, dynamic>.from(widget.order!);
    }
    _fetch();
  }

  Future<void> _fetch({bool force = false}) async {
    // Decide if we need to fetch:
    // 1. If explicit bookingId / idTransaksi provided -> fetch
    // 2. If only preloaded _data but it lacks orderSummary (null / empty) -> fetch using its booking_id
    final preloadedNeedsDetail =
        (_data != null) &&
        (_data!['orderSummary'] == null ||
            (_data!['orderSummary'] is List &&
                (_data!['orderSummary'] as List).isEmpty));
    if (!force &&
        widget.bookingId == null &&
        widget.idTransaksi == null &&
        _data != null &&
        !preloadedNeedsDetail) {
      return; // already have detailed data
    }
    setState(() => _loading = true);
    try {
      String? bookingId;
      int? idTransaksi;
      if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        bookingId = widget.bookingId;
      } else if (widget.idTransaksi != null) {
        idTransaksi = widget.idTransaksi;
      } else if (_data != null &&
          (_data!['booking_id'] ?? '').toString().isNotEmpty) {
        bookingId = _data!['booking_id'].toString();
      }
      if (bookingId == null && idTransaksi == null) {
        throw Exception('Tidak ada booking_id untuk fetch struk');
      }
      final res = await ReceiptPageService.fetchReceipt(
        bookingId: bookingId,
        idTransaksi: idTransaksi,
      );
      if (res.error != null) throw Exception(res.error!);
      _data = res.data;
      // Silent auto-cancel check (receipt context): jika masih konfirmasi_pembayaran & sudah lewat batas tanpa bukti
      try {
        if (_data != null) {
          await ReceiptPageService.autoCancelIfExpired(_data!);
        }
      } catch (_) {}
      // Normalisasi fallback
      if (_data != null &&
          _data!['orderSummary'] == null &&
          _data!['items'] is List) {
        _data!['orderSummary'] = _data!['items'];
      }
      await _checkReview();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void copyBookingId(BuildContext context, String bookingId) {
    Clipboard.setData(ClipboardData(text: bookingId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking ID berhasil disalin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data ?? {};
    final bookingId = (d['booking_id'] ?? d['id'] ?? '-').toString();
    final restaurantName = d['restaurantName'] ?? d['nama_resto'] ?? '-';
    final status = (d['status'] ?? '-').toString();
    const progressStatuses = [
      'konfirmasi_ketersediaan',
      'konfirmasi_pembayaran',
      'disiapkan',
      'diantar',
      'pickup',
    ];
    final isProgress = progressStatuses.contains(status);
    final displayStatus = isProgress
        ? 'Diproses'
        : (status.isNotEmpty
              ? status[0].toUpperCase() + status.substring(1)
              : '-');
    final iconPath = d['icon'] ?? 'lib/assets/images/spatulaknife.png';
    final locationSeller = d['locationSeller'] ?? '-';
    final locationBuyer = d['locationBuyer'] ?? '-';
    final jenisPengantaran = (d['jenis_pengantaran'] ?? '').toString();
    final bool isPickup = jenisPengantaran == 'pickup';
    // Fallback: gunakan 'items' bila 'orderSummary' kosong
    List<dynamic> orderSummary = (d['orderSummary'] as List<dynamic>?) ?? [];
    if (orderSummary.isEmpty && d['items'] is List) {
      orderSummary = List<dynamic>.from(d['items'] as List);
    }
    final subtotal =
        (d['subtotal'] ??
                orderSummary.fold<int>(
                  0,
                  (s, it) => s + ((it['price'] ?? 0) as int),
                ))
            as int;
    final deliveryFee = (d['delivery'] == true)
        ? (d['deliveryFee'] ?? d['biaya_pengantaran'] ?? 0)
        : 0;
    final total =
        (d['total'] ?? d['price'] ?? (subtotal + (deliveryFee as int))) as int;
    final alasanBatal = (status == 'dibatalkan')
        ? (d['catatan_pembatalan'] ?? '')
        : '';
    final selesai = status == 'selesai';
    final bool showProcessButton = isProgress;
    final bool showReviewButton = selesai && !_hasReview;
    final bool showAnyActionButtons = showProcessButton || showReviewButton;
    final reviewWidget = (_hasReview && _reviewData != null)
        ? Padding(
            padding: const EdgeInsets.only(top: 14.0, bottom: 12.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.reviews_rounded,
                        color: Color(0xFFB03056),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Ulasan Kamu',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF602829),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            ReviewSheetRoute(
                              ReviewPage(
                                idTransaksi: d['id_transaksi'] ?? 0,
                                idGerai: d['id_gerai'] ?? 0,
                                idUser: (_reviewData?['id_users'] ?? d['id_users'] ?? '').toString(),
                                geraiName: restaurantName.toString(),
                                listingPath: d['listing_path'] as String?,
                                readOnly: true,
                                initialRating: _reviewData?['rating'] as int?,
                                initialKomentar:
                                    _reviewData?['komentar'] as String?,
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4,
                          ),
                          child: Text(
                            'Lihat',
                            style: TextStyle(
                              color: Color(0xFFB03056),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      final ratingVal = (_reviewData?['rating'] ?? 0) as int;
                      return Padding(
                        padding: const EdgeInsets.only(right: 3.5),
                        child: Icon(
                          index < ratingVal
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 20,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  if (((_reviewData?['komentar'] ?? '') as String)
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      (_reviewData?['komentar'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true); // force parent refresh
        return false;
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            title: const Text(
              'Struk Pemesanan',
              style: TextStyle(
                color: AppTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  if (_reviewLoading)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: Color(0xFFB03056),
                    ),
                  const SizedBox(height: 6),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Error: ' + _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  Row(
                    children: [
                      const Text(
                        'Booking ID',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                bookingId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Color(0xFFB03056),
                                  size: 20,
                                ),
                                onPressed: () =>
                                    copyBookingId(context, bookingId),
                                tooltip: 'Copy',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Tanggal & waktu transaksi
                  Builder(
                    builder: (_) {
                      String? createdAt = d['created_at']?.toString();
                      if (createdAt == null || createdAt.isEmpty) {
                        final dateDisplay = d['dateDisplay']?.toString();
                        if (dateDisplay != null && dateDisplay.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              dateDisplay,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 6); // spacer minimal
                      }
                      DateTime? dt;
                      try {
                        dt = DateTime.parse(createdAt);
                      } catch (_) {}
                      if (dt == null) return const SizedBox.shrink();
                      String two(int v) => v.toString().padLeft(2, '0');
                      final formatted =
                          '${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}.${two(dt.minute)} WIB';
                      return Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          formatted,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
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
                          child: Image.asset(iconPath, width: 30, height: 30),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    restaurantName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status == 'selesai'
                                        ? Colors.green.withOpacity(.12)
                                        : (status == 'dibatalkan'
                                              ? Colors.red.withOpacity(.12)
                                              : Colors.orange.withOpacity(.15)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    displayStatus,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: .4,
                                      color: status == 'selesai'
                                          ? Colors.green.shade700
                                          : (status == 'dibatalkan'
                                                ? Colors.red.shade700
                                                : Colors.orange.shade800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (status == 'dibatalkan' &&
                                alasanBatal.toString().trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    maxWidth: 430,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F3),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE06577),
                                      width: 1.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE06577),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.cancel_outlined,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Pesanan Dibatalkan',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: .2,
                                                color: Color(0xFFB03056),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              alasanBatal.toString(),
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                height: 1.3,
                                                color: Color(0xFF602829),
                                                fontWeight: FontWeight.w500,
                                              ),
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
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (isPickup)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE4CCD5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFB03056).withOpacity(.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFFB03056),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurantName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF602829),
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  locationSeller,
                                  style: const TextStyle(
                                    fontSize: 13.2,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE4CCD5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEBD6DD),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  size: 16,
                                  color: Color(0xFFB03056),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurantName,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF602829),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (locationSeller
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          locationSeller,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                'lib/assets/images/iconLocation.png',
                                width: 26,
                                height: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  locationBuyer,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD9D9D9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Rangkuman Pemesanan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const Divider(
                          thickness: 2.5,
                          color: Color(0xFFB03056),
                          height: 0,
                        ),
                        if (orderSummary.isEmpty && _loading)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (orderSummary.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Detail pesanan tidak tersedia',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        else
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(1),
                            },
                            border: TableBorder.all(
                              style: BorderStyle.none,
                              color: Colors.transparent,
                            ),
                            children: [
                              ...orderSummary.asMap().entries.expand((entry) {
                                final item =
                                    entry.value as Map<String, dynamic>;
                                final List<TableRow> rows = [];
                                final qty =
                                    item['qty'] ?? item['quantity'] ?? 1;
                                final menu =
                                    item['menu'] ?? item['name'] ?? '-';
                                final itemPrice =
                                    item['price'] ?? item['subtotal'] ?? 0;
                                // Kumpulkan addons terlebih dahulu
                                List<String> addonNames = [];
                                final addonsDetail = item['addons_detail'];
                                if (addonsDetail is List &&
                                    addonsDetail.isNotEmpty) {
                                  addonNames = addonsDetail
                                      .map((a) {
                                        if (a is Map) {
                                          return (a['nama_addon'] ??
                                                  a['nama'] ??
                                                  a['name'])
                                              ?.toString();
                                        }
                                        return null;
                                      })
                                      .whereType<String>()
                                      .toList();
                                }
                                if (addonNames.isEmpty &&
                                    item['addons'] is List) {
                                  addonNames = (item['addons'] as List)
                                      .map(
                                        (e) => e is String
                                            ? e
                                            : (e is Map
                                                  ? (e['nama'] ?? e['name'])
                                                  : null),
                                      )
                                      .whereType<String>()
                                      .toList();
                                }
                                final note =
                                    (item['note'] ?? item['catatan'] ?? '')
                                        .toString()
                                        .trim();
                                // Satu TableRow saja: kolom kiri berisi nama + addon + catatan; kolom kanan harga center.
                                rows.add(
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          8,
                                          8,
                                          8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${qty}x  $menu',
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (addonNames.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                  left: 22,
                                                ),
                                                child: Text(
                                                  'Addon: ' +
                                                      addonNames.join(', '),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            if (note.isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: addonNames.isNotEmpty
                                                      ? 2
                                                      : 2,
                                                  left: 22,
                                                ),
                                                child: Text(
                                                  'Catatan: ' + note,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          8,
                                          8,
                                          8,
                                        ),
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: Text(
                                            'Rp${itemPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                return rows;
                              }),
                            ],
                          ),
                        if (orderSummary.isNotEmpty)
                          const Divider(
                            thickness: 1,
                            color: Color(0xFFD9D9D9),
                            height: 0,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Rp${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (deliveryFee > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ongkos Kirim',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Rp${deliveryFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(
                          thickness: 1,
                          color: Color(0xFFD9D9D9),
                          height: 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Rp${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Baris metode pembayaran di bawah Total
                        Builder(
                          builder: (_) {
                            // Ambil metode pembayaran dari beberapa kemungkinan key
                            String rawMetode = '';
                            for (final k in [
                              'metode_pembayaran',
                              'metodePembayaran',
                              'metode',
                              'payment_method',
                            ]) {
                              final v = d[k];
                              if (v != null && v.toString().trim().isNotEmpty) {
                                rawMetode = v.toString().trim().toLowerCase();
                                break;
                              }
                            }
                            if (rawMetode.isEmpty)
                              return const SizedBox.shrink();
                            String label = rawMetode == 'cash'
                                ? 'Tunai'
                                : (rawMetode == 'qris'
                                      ? 'QRIS'
                                      : rawMetode.toUpperCase());
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Text(
                                'Pembayaran: ' + label,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Relocated review widget appears here below order summary
                  reviewWidget,
                  SizedBox(height: showAnyActionButtons ? 14 : 8),
                  if (isProgress) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: CustomButtonKotak(
                        text: 'Lihat Proses Pesanan',
                        onPressed: () async {
                          final changed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CheckoutProcessPage(bookingId: bookingId),
                                ),
                              );
                          // Refresh bila proses mengembalikan true (status berubah) atau null tetapi kita tetap ingin update.
                          if (changed == true || changed == null) {
                            await _fetch(force: true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (showReviewButton) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: CustomButtonKotak(
                        text: 'Beri Ulasan',
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final rawIdUsers = prefs.get('id_users');
                          final idUsers = rawIdUsers?.toString();
                          if (idUsers == null) return;
                          final idTrans = d['id_transaksi'];
                          if (idTrans == null) return;
                          final idGeraiRaw = d['id_gerai'];
                          final idGerai = idGeraiRaw is int
                              ? idGeraiRaw
                              : int.tryParse(idGeraiRaw?.toString() ?? '') ?? 0;
                          final result = await Navigator.of(context).push(
                            ReviewSheetRoute(
                              ReviewPage(
                                idTransaksi: idTrans is int
                                    ? idTrans
                                    : int.tryParse(idTrans.toString()) ?? 0,
                                idGerai: idGerai,
                                idUser: idUsers,
                                geraiName: restaurantName,
                                listingPath: d['listing_path']?.toString(),
                              ),
                            ),
                          );
                          if (result == true) await _checkReview();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!showAnyActionButtons) const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: CustomButtonKotak(
                      text: 'Hubungi Kami',
                      onPressed: () {
                        // Aksi button
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
