import 'package:dpr_bites/features/user/pages/history/receipt_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart';
import 'package:dpr_bites/features/user/services/checkout_process_page_service.dart';
import 'package:dpr_bites/features/user/pages/checkout/chat_page.dart';
import 'package:dpr_bites/features/user/pages/checkout/pembayaran_qris_dialog.dart';
import 'package:dpr_bites/features/user/pages/review/review_page.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';
// SharedPreferences and HTTP are handled via CheckoutProcessPageService

class CheckoutProcessPage extends StatefulWidget {
  final String? bookingId;
  final int? idTransaksi;
  const CheckoutProcessPage({Key? key, this.bookingId, this.idTransaksi})
    : super(key: key);

  @override
  State<CheckoutProcessPage> createState() => _CheckoutProcessPageState();
}

// Tombol Chat Resto modern & minimalis
class _ChatRestoButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ChatRestoButton({Key? key, required this.onTap}) : super(key: key);

  @override
  State<_ChatRestoButton> createState() => _ChatRestoButtonState();
}

class _ChatRestoButtonState extends State<_ChatRestoButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFFB03056);
    final dark = const Color(0xFF602829);
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.95 : 1.0,
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base.withOpacity(.20), dark.withOpacity(.18)],
            ),
            border: Border.all(width: 1, color: base.withOpacity(.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_rounded,
                size: 16,
                color: base.withOpacity(.9),
              ),
              const SizedBox(width: 6),
              Text(
                'Chat',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: .2,
                  color: dark.withOpacity(.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutProcessPageState extends State<CheckoutProcessPage> {
  // Flag agar snackbar bukti pembayaran hanya muncul sekali
  bool _paymentProofNotified = false;
  OverlayEntry? _paymentProofOverlay;
  // (Payment banner visibility ditentukan langsung dari status & bukti_pembayaran)

  void _showPaymentProofToast() {
    if (_paymentProofOverlay != null) return; // already showing
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: MediaQuery.of(ctx).padding.top + 12,
          left: 12,
          right: 12,
          child: _PaymentProofToast(
            onDismiss: () {
              _paymentProofOverlay?.remove();
              _paymentProofOverlay = null;
            },
          ),
        );
      },
    );
    _paymentProofOverlay = entry;
    overlay.insert(entry);
    // Auto remove after 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _paymentProofOverlay == entry) {
        _paymentProofOverlay?.remove();
        _paymentProofOverlay = null;
      }
    });
  }

  void _showGenericTopToast({required String message, bool success = true}) {
    final overlay = Overlay.of(context);
    final color = success ? const Color(0xFF55B776) : const Color(0xFFB03056);
    final icon = success ? Icons.check_circle : Icons.error_rounded;
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 12,
        right: 12,
        child: _GenericToast(message: message, color: color, icon: icon),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }

  Map<String, dynamic>? _tx;
  List<Map<String, dynamic>> _items = [];
  // bool _loading = true; // dihapus, tidak dipakai
  // String? _error; // dihapus, tidak dipakai
  int _currentStep = 0; // 0..3
  bool _isPickup = false;
  late final String? _bookingId;
  late final int? _idTransaksi;
  Timer? _pollTimer; // periodic auto-refresh
  bool _fetching = false; // prevent overlapping fetch
  String _metode = '';
  DateTime?
  _paymentRequestedAt; // waktu pertama kali masuk konfirmasi_pembayaran
  static const Duration _paymentGrace = Duration(minutes: 10); // auto cancel
  static const Duration _paymentDisplayAdd = Duration(
    minutes: 10,
  ); // display pay before (was 15)
  DateTime? _disiapkanStart; // waktu pertama kali masuk status disiapkan
  DateTime?
  _diantarStart; // waktu pertama kali status menjadi diantar (delivery)
  final Duration _prepDuration = const Duration(minutes: 15);
  Duration _remaining = const Duration(minutes: 15);
  bool _timerScheduled = false;
  bool _overtime = false; // menandai jika sudah melewati estimasi
  DateTime?
  _selesaiAt; // waktu lokal ketika pertama kali status selesai terdeteksi (fallback jika backend belum kirim field khusus)
  DateTime?
  _firstFetchAt; // fallback waktu lokal pembuatan (approx) jika created_at tidak tersedia dari backend
  // status final dibatalkan/selesai hentikan polling
  bool get _finished =>
      _tx != null &&
      ['selesai', 'dibatalkan'].contains((_tx!['status'] ?? '').toString());
  bool _shownQris = false; // to avoid repeated dialog
  bool _shownReview = false; // avoid multi open
  String? _reviewOpenedAtStatus; // track status when review first opened
  bool _reviewSubmitted = false; // track if user already submitted
  bool _pushingReview = false; // guard against double push in same frame
  bool _autoCancelled = false; // menandai auto cancel sudah terjadi
  bool _timeoutDialogShown = false; // agar dialog hanya muncul sekali
  // Cache nama addon (id_addon -> nama_addon)
  final Map<int, String> _addonNameCache = {};
  int? _geraiId; // cache id gerai hasil resolve (backend mungkin belum kirim)
  String?
  _bookingCreatedAtDisplay; // cache format tanggal booking agar tidak hitung ulang tiap build
  bool _navigatedOnCancel = false; // navigate to history once when cancelled
  bool _qrisDialogOpen = false; // track QRIS dialog visibility

  Future<void> _resolveGeraiIdFromMenu(int idMenu) async {
    if (idMenu <= 0 || _geraiId != null) return;
    final gid = await CheckoutProcessPageService.resolveGeraiIdFromMenu(idMenu);
    if (gid != null) {
      _geraiId = gid;
      // ignore: avoid_print
      print('[GERAI RESOLVE OK] id_menu=$idMenu -> id_gerai=$_geraiId');
    }
  }

  Future<void> _fetch() async {
    if (_fetching) return; // avoid overlapping requests
    _fetching = true;
    setState(() {});
    try {
      final previousStatus = (_tx?['status'] ?? '').toString();
      final res = await CheckoutProcessPageService.fetchTransactionDetail(
        bookingId: _bookingId,
        idTransaksi: _idTransaksi,
      );
      if (!res.success) throw Exception('Gagal memuat transaksi');
      final data = res.tx;
      final status = (data['status'] ?? '').toString();
      // Reset flag agar dialog QRIS muncul saat pertama kali status masuk konfirmasi_pembayaran
      if (status == 'konfirmasi_pembayaran' &&
          previousStatus != 'konfirmasi_pembayaran') {
        _shownQris = false; // paksa tampil ulang
      }
      _metode = (data['metode_pembayaran'] ?? '').toString();
      _tx = data;
      _items = res.items;

      // If order just became cancelled, navigate to History (dibatalkan)
      // Skip auto-navigation when auto-cancel due to timeout to show popup instead
      if (previousStatus != 'dibatalkan' &&
          status == 'dibatalkan' &&
          !_navigatedOnCancel &&
          !_autoCancelled) {
        _navigatedOnCancel = true;
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const HistoryPage(initialFilter: 'dibatalkan'),
              ),
              (route) => false,
            );
          });
        }
        // Stop further processing for this fetch cycle
        return;
      }
      // Fallback isi id_users jika null supaya halaman ulasan bisa auto muncul
      if ((_tx!['id_users'] == null || _tx!['id_users'].toString().isEmpty)) {
        final uid = await CheckoutProcessPageService.getUserIdFromPrefs();
        if (uid != null) {
          _tx!['id_users'] = uid;
          // ignore: avoid_print
          print('[ReviewTrigger] Inject id_users via service val=$uid');
        }
      }
      _firstFetchAt ??= DateTime.now();
      // Simpan created_at terformat sekali (format: dd-MM-yyyy HH.mm WIB)
      _bookingCreatedAtDisplay = _formatTanggalBooking(data);
      if ((_bookingCreatedAtDisplay == null ||
              _bookingCreatedAtDisplay!.isEmpty) &&
          _firstFetchAt != null) {
        _bookingCreatedAtDisplay = _formatDateCompact(_firstFetchAt!) + ' WIB';
      }
      // DEBUG per item
      for (final it in _items) {
        // ignore: avoid_print
        print(
          '[ITEM DEBUG] name=${it['name'] ?? it['menu']} addons=${it['addons']} addons_detail=${it['addons_detail']}',
        );
      }
      _isPickup = (data['jenis_pengantaran'] ?? '') == 'pickup';
      _currentStep = _mapStatusToStep(status, _isPickup, _metode);
      // Catat & persist waktu mulai window pembayaran hanya sekali per booking
      if (status == 'konfirmasi_pembayaran') {
        final bookingId = (data['booking_id'] ?? '').toString();
        if (bookingId.isNotEmpty) {
          if (_paymentRequestedAt == null) {
            _paymentRequestedAt =
                await CheckoutProcessPageService.loadPaymentStart(bookingId);
          }
          _paymentRequestedAt ??= DateTime.now();
          await CheckoutProcessPageService.persistPaymentStart(
            bookingId,
            _paymentRequestedAt!,
          );
        }
      } else {
        if (_paymentRequestedAt != null) {
          final bookingId = (_tx?['booking_id'] ?? '').toString();
          if (bookingId.isNotEmpty) {
            await CheckoutProcessPageService.removePaymentStart(bookingId);
          }
        }
        _paymentRequestedAt = null;
      }
      // Pastikan nama addon tersedia bila backend belum kirim detail
      final idGerai = data['id_gerai'];
      if (idGerai != null) {
        _geraiId = idGerai is int ? idGerai : int.tryParse(idGerai.toString());
      }
      // Fallback: resolve id_gerai via id_menu bila belum ada
      if (_geraiId == null && _items.isNotEmpty) {
        final idMenuRaw = _items.first['id_menu'];
        int? idMenuInt = idMenuRaw is int
            ? idMenuRaw
            : (idMenuRaw != null ? int.tryParse(idMenuRaw.toString()) : null);
        if (idMenuInt != null) {
          await _resolveGeraiIdFromMenu(idMenuInt);
        }
      }
      if (_geraiId != null) {
        await _ensureAddonNames(_geraiId!, _items);
      } else {
        // ignore: avoid_print
        print(
          '[WARN] id_gerai tidak tersedia sehingga addon tidak bisa di-resolve',
        );
      }
      // Catat / pulihkan waktu mulai disiapkan untuk countdown (pickup saja)
      // dan waktu mulai diantar untuk ETA statis delivery
      if (status == 'diantar') {
        // Untuk delivery, simpan waktu pertama kali status menjadi 'diantar'
        final idTransaksi = data['id_transaksi'];
        final key = idTransaksi == null
            ? null
            : 'diantar_start_${idTransaksi.toString()}';
        if (_diantarStart == null && key != null) {
          _diantarStart = await CheckoutProcessPageService.loadDiantarStart(
            idTransaksi is int
                ? idTransaksi
                : int.tryParse(idTransaksi.toString()) ?? -1,
          );
          _diantarStart ??= DateTime.now();
          final id = idTransaksi is int
              ? idTransaksi
              : int.tryParse(idTransaksi.toString());
          if (id != null) {
            await CheckoutProcessPageService.persistDiantarStart(
              id,
              _diantarStart!,
            );
          }
        }
      } else if (status == 'disiapkan') {
        // Countdown timer untuk disiapkan, baik pickup maupun pengantaran
        _timerScheduled =
            false; // reset agar timer bisa dijalankan ulang jika status berubah
        final idTransaksi = data['id_transaksi'];
        final key = idTransaksi == null
            ? null
            : 'prep_start_${idTransaksi.toString()}';
        if (_disiapkanStart == null && key != null) {
          _disiapkanStart = await CheckoutProcessPageService.loadPrepStart(
            idTransaksi is int
                ? idTransaksi
                : int.tryParse(idTransaksi.toString()) ?? -1,
          );
          _disiapkanStart ??= DateTime.now();
          final id = idTransaksi is int
              ? idTransaksi
              : int.tryParse(idTransaksi.toString());
          if (id != null) {
            await CheckoutProcessPageService.persistPrepStart(
              id,
              _disiapkanStart!,
            );
          }
        }
        if (_disiapkanStart != null) {
          final elapsed = DateTime.now().difference(_disiapkanStart!);
          final remaining = _prepDuration - elapsed;
          if (remaining <= Duration.zero) {
            _remaining = Duration.zero;
            _overtime = true;
          } else {
            _remaining = remaining;
          }
          if (!_timerScheduled) _scheduleCountdownTick();
        }
      } else {
        _timerScheduled =
            false; // reset agar timer bisa dijalankan ulang jika status berubah
        // Jika keluar dari status disiapkan (antar/pickup/selesai/dibatalkan) hapus key agar sesi baru dimulai wajar bila perlu.
        if (_disiapkanStart != null) {
          final idTransaksi = data['id_transaksi'];
          if (idTransaksi != null) {
            final id = idTransaksi is int
                ? idTransaksi
                : int.tryParse(idTransaksi.toString());
            if (id != null) {
              await CheckoutProcessPageService.removePrepStart(id);
            }
          }
        }
        // Jika keluar dari status diantar (selesai/dibatalkan/disiapkan/pickup) hapus key agar sesi baru dimulai wajar bila perlu.
        if (_diantarStart != null && status != 'diantar') {
          final idTransaksi = data['id_transaksi'];
          if (idTransaksi != null) {
            final id = idTransaksi is int
                ? idTransaksi
                : int.tryParse(idTransaksi.toString());
            if (id != null) {
              await CheckoutProcessPageService.removeDiantarStart(id);
            }
          }
          _diantarStart = null;
        }
      }
      // Catat waktu selesai lokal bila status selesai muncul pertama kali (gunakan field backend jika tersedia)
      if (status == 'selesai' && _selesaiAt == null) {
        // Jika backend menyediakan 'waktu_selesai' atau 'completed_at', coba parse
        DateTime? backendDone;
        for (final key in [
          'waktu_selesai',
          'completed_at',
          'tanggal_selesai',
          'updated_at',
        ]) {
          final v = data[key];
          if (v is String && v.trim().isNotEmpty) {
            try {
              backendDone = DateTime.parse(v);
              break;
            } catch (_) {}
          }
        }
        _selesaiAt = backendDone ?? DateTime.now();
      }
      setState(() {});
      _maybeShowQrisDialog();
      _maybeShowReview(); // otomatis buka halaman ulasan saat status selesai
      _maybeAutoCancelPayment();
      // Tampilkan dialog timeout jika status berubah ke dibatalkan dari konfirmasi_pembayaran oleh auto cancel
      if (_autoCancelled &&
          !_timeoutDialogShown &&
          status == 'dibatalkan' &&
          previousStatus == 'konfirmasi_pembayaran') {
        _timeoutDialogShown = true;
        _showTimeoutDialog();
      }
      // _schedulePoll digantikan oleh Timer.periodic
    } catch (e) {
      setState(() {
        // error diabaikan
        // loading diabaikan
      });
    } finally {
      _fetching = false;
    }
  }

  void _maybeAutoCancelPayment() async {
    if (!mounted) return;
    if (_tx == null) return;
    if ((_tx!['status'] ?? '') != 'konfirmasi_pembayaran') return;
    if (_paymentRequestedAt == null) return;
    // Jika sudah ada bukti pembayaran (upload sedang menunggu verifikasi) jangan auto-cancel
    if ((_tx!['bukti_pembayaran'] ?? '').toString().isNotEmpty) return;
    final elapsed = DateTime.now().difference(_paymentRequestedAt!);
    if (elapsed >= _paymentGrace) {
      // auto cancel
      _autoCancelled = true;
      await CheckoutProcessPageService.updateTransactionStatus(
        bookingId: _tx!['booking_id'].toString(),
        newStatus: 'dibatalkan',
        alasan: 'Pembayaran Dibatalkan',
      );
      await _fetch();
    } else {
      // schedule next check shortly
      Future.delayed(const Duration(seconds: 30), () {
        _maybeAutoCancelPayment();
      });
    }
  }

  void _showTimeoutDialog() {
    if (!mounted) return;
    // Close QRIS dialog first if it's open to avoid stacked dialogs
    if (_qrisDialogOpen) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      _qrisDialogOpen = false;
    }
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Timeout',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Opacity(
          opacity: curved.value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * curved.value),
            child: Center(
              child: _TimeoutDialog(
                onConfirm: () {
                  // Close the dialog using the root navigator to ensure overlay is dismissed
                  if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                    Navigator.of(ctx, rootNavigator: true).pop();
                  }
                  if (!mounted) return;
                  // Schedule navigation on next frame to avoid acting during dialog teardown
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            const HistoryPage(initialFilter: 'dibatalkan'),
                      ),
                      (route) => false,
                    );
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnifiedPaymentBanner() {
    final now = DateTime.now();
    // Gunakan waktu persist agar label tidak bergeser setiap rebuild
    final payBefore = (_paymentRequestedAt ?? now).add(_paymentDisplayAdd);
    String two(int v) => v.toString().padLeft(2, '0');
    final label = '${two(payBefore.hour)}.${two(payBefore.minute)} WIB';
    final isQris = (_tx?['metode_pembayaran'] ?? '').toString() == 'qris';
    return GestureDetector(
      onTap: () {
        if (isQris) {
          _shownQris = false; // reopen dialog
          _maybeShowQrisDialog();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFB03056).withOpacity(0.10),
              const Color(0xFFB03056).withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFB03056).withOpacity(0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB03056).withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFB03056).withOpacity(0.90),
                    const Color(0xFFB03056).withOpacity(0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                isQris ? Icons.qr_code_2_rounded : Icons.payments_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bayar sebelum $label',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.25,
                      color: Color(0xFF602829),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isQris
                        ? 'Ketuk untuk membuka QRIS & unggah bukti pembayaran'
                        : 'Selesaikan pembayaran Anda sebelum batas waktu',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            if (isQris)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFFB03056),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _ensureAddonNames(
    int idGerai,
    List<Map<String, dynamic>> items,
  ) async {
    if (idGerai <= 0) return;
    // Jika semua item sudah punya addons_detail atau tidak ada addons, skip
    final needsFetch = items.any((it) {
      final ads = it['addons'];
      final detail = it['addons_detail'];
      if (detail is List && detail.isNotEmpty) return false; // sudah punya
      if (ads is String && ads.trim().isNotEmpty) return true; // csv
      if (ads is List && ads.isNotEmpty) return true; // butuh map id->nama
      return false;
    });
    if (!needsFetch) return;
    // Skip kalau cache sudah punya semua id yang diperlukan
    final idsNeeded = <int>{};
    for (final it in items) {
      final ads = it['addons'];
      if (ads is List) {
        for (final a in ads) {
          if (a is int) {
            idsNeeded.add(a);
          } else if (a is String) {
            final v = int.tryParse(a);
            if (v != null) idsNeeded.add(v);
          }
        }
      } else if (ads is String) {
        // dukung format "1,2,3"
        for (final part in ads.split(',')) {
          final v = int.tryParse(part.trim());
          if (v != null) idsNeeded.add(v);
        }
      }
    }
    if (idsNeeded.isEmpty) return;
    if (idsNeeded.every((id) => _addonNameCache.containsKey(id))) return;
    final map = await CheckoutProcessPageService.fetchAddonNameMapByGerai(
      idGerai,
    );
    if (map.isNotEmpty) {
      _addonNameCache.addAll(map);
    }
    // ignore: avoid_print
    print('[ADDON CACHE] $_addonNameCache');
    if (mounted) {
      setState(() {});
    }
  }

  void _maybeShowQrisDialog() {
    if (!mounted) return;
    if (_shownQris) return;
    if (_tx == null) return;
    final status = (_tx!['status'] ?? '').toString();
    final metode = (_tx!['metode_pembayaran'] ?? '').toString();
    if (status == 'konfirmasi_pembayaran' && metode == 'qris') {
      _shownQris = true;
      _qrisDialogOpen = true;
      final qrisPath = (_tx!['qris_path'] ?? '').toString();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return PembayaranQrisDialog(
            qrisImageUrl: qrisPath.isEmpty ? null : qrisPath,
            showDownload: true,
            bookingId: (_tx?['booking_id'] ?? widget.bookingId)?.toString(),
            totalPembayaran: _computeTotalPembayaran(),
            onKonfirmasi: (file) async {
              final r = await CheckoutProcessPageService.uploadPaymentProof(
                bookingId: _tx!['booking_id'].toString(),
                file: file,
              );
              if (!mounted) return;
              if (r.success) {
                setState(() {
                  _tx = Map<String, dynamic>.from(_tx!);
                  _tx!['bukti_pembayaran'] = 'uploaded';
                });
                _showGenericTopToast(
                  message: 'Bukti pembayaran terkirim',
                  success: true,
                );
                unawaited(_fetch());
              } else {
                _showGenericTopToast(
                  message: r.message ?? 'Upload bukti gagal',
                  success: false,
                );
              }
            },
            onBatal: () {
              // Sekarang hanya menutup dialog tanpa membatalkan pesanan.
            },
          );
        },
      ).then((_) {
        _qrisDialogOpen = false;
      });
    }
  }

  int? _computeTotalPembayaran() {
    try {
      if (_items.isEmpty) return null;
      int grand = 0;
      for (final it in _items) {
        final subtotalRaw = it['subtotal'];
        int? subtotal = _asInt(subtotalRaw);
        if (subtotal == null) {
          final qty = _asInt(it['qty']) ?? 1;
          final hargaSatuan = _asInt(it['harga_satuan']) ?? 0;
          int addonsSum = 0;
          final addons = it['addons'];
          if (addons is List) {
            for (final a in addons) {
              if (a is Map) {
                final h = _asInt(a['harga']) ?? 0;
                addonsSum += h;
              }
            }
          }
          subtotal = qty * (hargaSatuan + addonsSum);
        }
        grand += subtotal;
      }
      return grand;
    } catch (_) {
      return null;
    }
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> _maybeShowReview({bool overrideShown = false}) async {
    if (!mounted) return;
    if (_tx == null) return;
    final raw = (_tx!['status'] ?? '').toString();
    final status = raw.trim().toLowerCase();
    final debugPrefix = '[ReviewTrigger]';
    // Only open at final status 'selesai'.
    if (status != 'selesai') {
      // ignore: avoid_print
      print('$debugPrefix BATAL: status=$status (bukan selesai)');
      return;
    }
    if (_reviewSubmitted) {
      // ignore: avoid_print
      print('$debugPrefix BATAL: sudah submit');
      return;
    }
    if (_pushingReview) {
      // ignore: avoid_print
      print('$debugPrefix BATAL: masih pushing');
      return;
    }
    if (_shownReview && _reviewOpenedAtStatus == 'selesai' && !overrideShown) {
      // ignore: avoid_print
      print('$debugPrefix BATAL: sudah pernah dibuka & overrideShown=false');
      return;
    }
    // Require essential ids
    final idTransaksi = _tx!['id_transaksi'];
    if (_tx!['id_gerai'] == null && _geraiId != null) {
      _tx!['id_gerai'] = _geraiId;
    }
    final idGerai = _tx!['id_gerai'];
    final idUser = _tx!['id_users']?.toString();
    if (idTransaksi == null ||
        idGerai == null ||
        idUser == null ||
        idUser.isEmpty) {
      // ignore: avoid_print
      print(
        '$debugPrefix BATAL: id null (idTransaksi=$idTransaksi, idGerai=$idGerai, idUser=$idUser)',
      );
      return;
    }
    _pushingReview = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _pushingReview = false;
        return;
      }
      _shownReview = true;
      _reviewOpenedAtStatus = 'selesai';
      // ignore: avoid_print
      print(
        '$debugPrefix PUSH: membuka halaman ulasan (overrideShown=$overrideShown)',
      );
      Navigator.of(context)
          .push(
            ReviewSheetRoute(
              ReviewPage(
                idTransaksi: idTransaksi is int
                    ? idTransaksi
                    : int.tryParse(idTransaksi.toString()) ?? 0,
                idGerai: idGerai is int
                    ? idGerai
                    : int.tryParse(idGerai.toString()) ?? 0,
                idUser: idUser,
                geraiName: (_tx!['restaurantName'] ?? '').toString(),
                listingPath: (() {
                  final v = _tx!['listing_path'] ?? _tx!['listingPath'];
                  return v == null ? null : v.toString();
                })(),
              ),
            ),
          )
          .then((value) {
            if (value == true) {
              _reviewSubmitted = true;
              // ignore: avoid_print
              print('$debugPrefix RESULT: submit berhasil');
            } else {
              // ignore: avoid_print
              print('$debugPrefix RESULT: ditutup tanpa submit');
            }
            _pushingReview = false;
          });
    });
  }

  int _mapStatusToStep(String status, bool pickup, String metode) {
    // Jika metode cash: lewati konfirmasi_pembayaran -> langkah index bergeser
    // Langkah definisi (untuk qris): 0 konfirmasi resto,1 konfirmasi pembayaran,2 disiapkan,3 antar/pickup
    // Untuk cash: 0 konfirmasi resto,1 disiapkan,2 antar/pickup (kita map supaya UI tetap 4 slot tapi step 1 (pembayaran) akan disabled/transparan)
    // NOTE: Untuk status 'selesai' kita geser index +1 agar step terakhir dianggap sudah DONE (warna abu-abu) bukan current highlight.
    final isCash = metode == 'cash';
    // Cash steps: 0 konfirmasi resto,1 disiapkan,2 antar/pickup, selesai -> 3 (out of range to mark done)
    // Non-cash steps: 0 konfirmasi resto,1 konfirmasi pembayaran,2 disiapkan,3 antar/pickup, selesai -> 4
    switch (status) {
      case 'konfirmasi_ketersediaan':
        return 0;
      case 'konfirmasi_pembayaran':
        return isCash ? 0 : 1;
      case 'disiapkan':
        return isCash ? 1 : 2;
      case 'diantar':
      case 'pickup':
        return isCash ? 2 : 3;
      case 'selesai':
        return isCash ? 3 : 4; // out-of-range to grey out last
      case 'dibatalkan':
        return 0;
      default:
        return 0;
    }
  }

  void _scheduleCountdownTick() {
    if (_timerScheduled) return; // single chain
    _timerScheduled = true;
    Future.doWhile(() async {
      if (!mounted) return false;
      if (_disiapkanStart == null) return false;
      final elapsed = DateTime.now().difference(_disiapkanStart!);
      final remaining = _prepDuration - elapsed;
      if (remaining <= Duration.zero) {
        setState(() {
          _remaining = Duration.zero;
          _overtime = true;
        });
        return false; // stop timer
      }
      setState(() {
        _remaining = remaining;
      });
      await Future.delayed(const Duration(seconds: 1));
      return true;
    });
  }

  List<_StepProcess> _buildSteps() {
    final isCash = _metode == 'cash';
    // Jika cash: hilangkan sepenuhnya step "Konfirmasi Pembayaran" (bukan disabled).
    if (isCash) {
      return [
        _StepProcess(
          icon: 'lib/assets/images/iconCheck.png',
          label: 'Menunggu Konfirmasi Resto',
          stateIndex: 0,
        ),
        _StepProcess(
          icon: 'lib/assets/images/spatulaknife.png',
          label: 'Makanan Lagi Disiapin',
          stateIndex: 1,
        ),
        _StepProcess(
          icon: _isPickup
              ? 'material:store'
              : 'lib/assets/images/iconDelivery.png',
          label: _isPickup
              ? 'Makanan Siap untuk Diambil'
              : 'Makanan Dalam Perjalanan',
          stateIndex: 2,
        ),
      ];
    }
    // Non-cash (qris) tetap 4 langkah termasuk Konfirmasi Pembayaran.
    return [
      _StepProcess(
        icon: 'lib/assets/images/iconCheck.png',
        label: 'Menunggu Konfirmasi Resto',
        stateIndex: 0,
      ),
      _StepProcess(icon: '', label: 'Konfirmasi Pembayaran', stateIndex: 1),
      _StepProcess(
        icon: 'lib/assets/images/spatulaknife.png',
        label: 'Makanan Lagi Disiapin',
        stateIndex: 2,
      ),
      _StepProcess(
        icon: _isPickup
            ? 'material:store'
            : 'lib/assets/images/iconDelivery.png',
        label: _isPickup
            ? 'Makanan Siap untuk Diambil'
            : 'Makanan Dalam Perjalanan',
        stateIndex: 3,
      ),
    ];
  }

  // Format dari field created_at saja -> "dd-MM-yyyy HH.mm WIB"
  String _formatTanggalBooking(Map<String, dynamic>? tx) {
    if (tx == null) return '';
    final raw = tx['created_at'] ?? tx['createdAt'];
    if (raw is! String || raw.trim().isEmpty) return '';
    var s = raw.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2} ').hasMatch(s) && !s.contains('T')) {
      s = s.replaceFirst(' ', 'T');
    }
    // Jika format dd-MM-yyyy HH:MM:SS
    final m = RegExp(
      r'^(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2})(:(\d{2}))?',
    ).firstMatch(s);
    DateTime? dt;
    if (m != null) {
      try {
        dt = DateTime(
          int.parse(m.group(3)!),
          int.parse(m.group(2)!),
          int.parse(m.group(1)!),
          int.parse(m.group(4)!),
          int.parse(m.group(5)!),
          m.group(7) != null ? int.parse(m.group(7)!) : 0,
        );
      } catch (_) {
        dt = null;
      }
    } else {
      try {
        dt = DateTime.parse(s);
      } catch (_) {
        dt = null;
      }
    }
    if (dt == null) return '';
    dt = dt.toLocal();
    return _formatDateCompact(dt) + ' WIB';
  }

  String _formatDateCompact(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final HH = dt.hour.toString().padLeft(2, '0');
    final MM = dt.minute.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy $HH.$MM';
  }

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _idTransaksi = widget.idTransaksi;
    // Mulai fetch hanya jika ada identitas transaksi, kalau tidak biarkan dummy tampil
    final b = _bookingId;
    if ((b != null && b.isNotEmpty) || _idTransaksi != null) {
      _fetch();
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (t) {
        if (!mounted) return;
        if (_finished) {
          t.cancel();
          return;
        }
        _fetch();
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fallback dummy jika belum fetch agar struktur UI utuh
    final restaurantName =
        (_tx != null
                ? _tx!['restaurantName']
                : (dummyCheckout['restaurantName']))
            ?.toString() ??
        '';
    final locationSeller = _tx != null
        ? (_tx!['locationSeller'] ?? '')
        : (dummyCheckout['locationSeller'] ?? '');
    final locationBuyer = _tx != null
        ? (_tx!['locationBuyer'] ?? '')
        : (dummyCheckout['locationBuyer'] ?? '');
    final buildingNameBuyer = _tx != null
        ? (_tx!['buildingNameBuyer'] ?? '')
        : '';
    // Untuk tampilan alamat: jika delivery tampilkan "nama gedung - detail pengantaran"
    final locationDetail = _isPickup
        ? locationSeller
        : [
            if (buildingNameBuyer.toString().trim().isNotEmpty)
              buildingNameBuyer.toString().trim(),
            if (locationBuyer.toString().trim().isNotEmpty)
              locationBuyer.toString().trim(),
          ].join(' - ');
    final items = _items.isNotEmpty
        ? _items
        : (List<Map<String, dynamic>>.from(dummyCheckout['items'] as List));
    final steps = _buildSteps();
    // Tampilkan snackbar sukses bukti pembayaran (one-shot) bila baru ada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_paymentProofNotified &&
          (_tx?['status'] == 'konfirmasi_pembayaran') &&
          ((_tx?['bukti_pembayaran'] ?? '').toString().isNotEmpty)) {
        _paymentProofNotified = true;
        if (mounted) _showPaymentProofToast();
      }
    });
    // cancelled & note prepared (not rendered to avoid layout change)
    // Removed unused local vars (cancelled, cancellationNote) to satisfy analyzer.

    return WillPopScope(
      onWillPop: () async {
        // Always signal cart to refresh after leaving checkout process
        Navigator.of(context).pop(true);
        return false; // we've handled the pop
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFB03056)),
              onPressed: () => Navigator.of(
                context,
              ).pop(true), // return true so CartPage refetches
            ),
            title: const Text(
              'Detail Status Pemesanan',
              style: TextStyle(
                color: Color(0xFF602829),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Proses status dan waktu
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 8,
                        bottom: 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stepper vertical
                          Column(
                            children: List.generate(steps.length * 2 - 1, (i) {
                              if (i.isEven) {
                                final stepIndex = i ~/ 2;
                                final step = steps[stepIndex];
                                final realIndex = step.stateIndex;
                                final isCurrent = realIndex == _currentStep;
                                final isDone = realIndex < _currentStep;
                                return _ProcessIcon(
                                  icon: step.icon,
                                  isActive: isDone || isCurrent,
                                  isDone: isDone,
                                  size: isCurrent ? 54 : 40,
                                  iconSize: isCurrent ? 34 : 24,
                                );
                              } else {
                                return Container(
                                  width: 2,
                                  height: 32,
                                  child: CustomPaint(
                                    painter: _DashedLinePainter(),
                                  ),
                                );
                              }
                            }),
                          ),
                          const SizedBox(width: 16),
                          // Label dan waktu
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(steps.length * 2 - 1, (
                                i,
                              ) {
                                if (i.isEven) {
                                  final stepIndex = i ~/ 2;
                                  final step = steps[stepIndex];
                                  final realIndex = step.stateIndex;
                                  // Bila _currentStep melampaui jumlah step (misal selesai) maka tidak ada current di daftar; semua < current jadi done
                                  final isCurrent =
                                      realIndex == _currentStep &&
                                      realIndex < steps.length;
                                  final isDone =
                                      realIndex < _currentStep &&
                                      realIndex < steps.length;
                                  final isFuture = realIndex > _currentStep;
                                  Color color;
                                  if (isCurrent) {
                                    color = const Color(0xFFB03056);
                                  } else if (isDone) {
                                    color = Colors.grey;
                                  } else if (isFuture) {
                                    color = Colors.grey.withOpacity(0.55);
                                  } else {
                                    color = const Color(0xFF602829);
                                  }
                                  return SizedBox(
                                    height: isCurrent ? 54 : 40,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        step.label,
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: isCurrent ? 14 : 13,
                                          color: color,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                        softWrap: true,
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox(height: 32);
                                }
                              }),
                            ),
                          ),
                          // Panel waktu / estimasi
                          if (_currentStep >= (_metode == 'cash' ? 1 : 2))
                            SizedBox(
                              width:
                                  170, // lebar tetap agar kolom label tidak terhimpit
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8, left: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 80),
                                    LayoutBuilder(
                                      builder: (context, cons) {
                                        // Sesuaikan font berdasarkan lebar agar tidak overflow
                                        final narrow = cons.maxWidth < 160;
                                        final titleStyleBase = TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: narrow ? 16 : 20,
                                          color: const Color(0xFF602829),
                                          height: 1.15,
                                        );
                                        final timeStyle = TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: narrow ? 28 : 32,
                                          color: const Color(0xFFB03056),
                                          letterSpacing: 0.5,
                                        );
                                        final statusNow = (_tx?['status'] ?? '')
                                            .toString();
                                        if (statusNow == 'selesai') {
                                          return SizedBox(
                                            width: double.infinity,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pesanan Selesai',
                                                  style: titleStyleBase
                                                      .copyWith(
                                                        fontSize: narrow
                                                            ? 16
                                                            : 18,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_formatClock(_selesaiAt ?? DateTime.now())} WIB',
                                                  style: timeStyle,
                                                ),
                                              ],
                                            ),
                                          );
                                        } else if (statusNow == 'diantar' ||
                                            statusNow == 'pickup') {
                                          if (statusNow == 'pickup') {
                                            return SizedBox(
                                              width: double.infinity,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Pesanan Siap Untuk di Pick Up',
                                                    textAlign: TextAlign.center,
                                                    style: titleStyleBase
                                                        .copyWith(
                                                          fontSize: narrow
                                                              ? 16
                                                              : 18,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            // Delivery: ETA statis, ambil dari _diantarStart + 15 menit
                                            DateTime? eta;
                                            if (_diantarStart != null) {
                                              eta = _diantarStart!.add(
                                                const Duration(minutes: 15),
                                              );
                                            }
                                            return SizedBox(
                                              width: double.infinity,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Estimasi',
                                                    style: titleStyleBase
                                                        .copyWith(
                                                          fontSize: narrow
                                                              ? 14
                                                              : 16,
                                                          height: 1.1,
                                                        ),
                                                  ),
                                                  FittedBox(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'Pesanan Diterima',
                                                      maxLines: 1,
                                                      softWrap: false,
                                                      style: titleStyleBase
                                                          .copyWith(
                                                            fontSize: narrow
                                                                ? 14
                                                                : 16,
                                                            height: 1.1,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    eta != null
                                                        ? '${_formatClock(eta)} WIB'
                                                        : '-',
                                                    style: timeStyle,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        } else {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              if (_overtime)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        12,
                                                        10,
                                                        12,
                                                        10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(
                                                          0xFFB03056,
                                                        ).withOpacity(.12),
                                                        const Color(
                                                          0xFF602829,
                                                        ).withOpacity(.08),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFB03056,
                                                      ).withOpacity(.35),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Mohon Maaf Pesanan Disiapkan Lebih Lama dari Perkiraan. Mohon Untuk Menunggu.',
                                                    style: titleStyleBase
                                                        .copyWith(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          height: 1.3,
                                                          color: const Color(
                                                            0xFF602829,
                                                          ),
                                                        ),
                                                    textAlign: TextAlign.left,
                                                  ),
                                                )
                                              else ...[
                                                if (_isPickup) ...[
                                                  Center(
                                                    child: Text(
                                                      'Pesanan Siap Untuk di Pick Up',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: titleStyleBase
                                                          .copyWith(
                                                            fontSize: narrow
                                                                ? 16
                                                                : 18,
                                                          ),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  Text(
                                                    'Diantar Dalam',
                                                    style: titleStyleBase
                                                        .copyWith(
                                                          fontSize: narrow
                                                              ? 16
                                                              : 18,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatRemaining(
                                                      _remaining,
                                                    ),
                                                    style: timeStyle,
                                                  ),
                                                ],
                                              ],
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Unified Payment Banner (dipindah ke atas nama resto)
                    if ((_tx?['status'] == 'konfirmasi_pembayaran') &&
                        ((_tx?['bukti_pembayaran'] ?? '').toString().isEmpty))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildUnifiedPaymentBanner(),
                      ),
                    if ((_tx?['status'] == 'konfirmasi_pembayaran') &&
                        ((_tx?['bukti_pembayaran'] ?? '').toString().isEmpty))
                      const SizedBox(height: 12),
                    // Nama resto (utama) + alamat detail kecil + chat
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurantName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF602829),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (locationSeller.toString().trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      locationSeller.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(
                                          0xFF602829,
                                        ), // ganti dari abu-abu ke warna utama
                                        height: 1.2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _ChatRestoButton(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      restaurantName: restaurantName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Card info pesanan
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CustomEmptyCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(
                                builder: (context) {
                                  final bookingId =
                                      (_tx?['booking_id']?.toString() ??
                                              _bookingId ??
                                              '')
                                          .trim();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Pickup: gunakan ikon toko (store), Delivery: ikon delivery (asset)
                                          _isPickup
                                              ? const Icon(
                                                  Icons.store,
                                                  size: 36,
                                                  color: Color(0xFFB03056),
                                                )
                                              : Image.asset(
                                                  'lib/assets/images/iconDelivery.png',
                                                  width: 36,
                                                  height: 36,
                                                ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _isPickup
                                                  ? 'Pick Up'
                                                  : 'Pesan Antar',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 21,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          if (bookingId.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  bookingId,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 36,
                                                        minHeight: 36,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.copy,
                                                    size: 18,
                                                    color: Colors.black,
                                                  ),
                                                  tooltip: 'Salin Booking ID',
                                                  onPressed: () async {
                                                    await Clipboard.setData(
                                                      ClipboardData(
                                                        text: bookingId,
                                                      ),
                                                    );
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Booking ID disalin',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              FractionallySizedBox(
                                widthFactor: 1,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0x47000000,
                                    ), // 0x47 = 28% opacity
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment
                                    .center, // center ikon dengan blok teks Nama Restoran
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
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
                                        'lib/assets/images/spatulaknife.png',
                                        width: 22,
                                        height: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Nama Restoran',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          restaurantName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black,
                                          ),
                                        ),
                                        // alamat detail dipindah ke header atas
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
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
                                        'lib/assets/images/iconLocation.png',
                                        width: 22,
                                        height: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isPickup
                                              ? 'Alamat Pick Up'
                                              : 'Alamat Antar',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          locationDetail.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Catatan global dihapus; catatan per item dipindah ke daftar Pesanan Kamu
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Pesanan Kamu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CustomEmptyCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(
                                builder: (context) {
                                  final bookingTimeStr =
                                      _bookingCreatedAtDisplay ??
                                      _formatTanggalBooking(_tx);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Pesanan Kamu',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (bookingTimeStr.isNotEmpty)
                                            Text(
                                              bookingTimeStr,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                      // Baris info metode pembayaran (diminta muncul tepat di bawah judul Pesanan Kamu)
                                      Builder(
                                        builder: (_) {
                                          final m = _metode
                                              .trim()
                                              .toLowerCase();
                                          if (m.isEmpty)
                                            return const SizedBox.shrink();
                                          String label;
                                          switch (m) {
                                            case 'cash':
                                              label = 'Tunai';
                                              break;
                                            case 'qris':
                                              label = 'QRIS';
                                              break;
                                            default:
                                              label = m.toUpperCase();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              'Pembayaran: ' + label,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      FractionallySizedBox(
                                        widthFactor: 1,
                                        child: Container(
                                          height: 2,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0x47000000,
                                            ), // 28% opacity
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                },
                              ),
                              // (divider lama di bawah sudah tidak diperlukan karena sudah ada di builder di atas)
                              ...items.map((item) {
                                final baseName =
                                    (item['name'] ?? item['menu'] ?? '')
                                        .toString();
                                final List<String> addonNames = [];
                                bool shouldHaveAddon = false;
                                final rawDetail = item['addons_detail'];
                                if (rawDetail is List && rawDetail.isNotEmpty) {
                                  shouldHaveAddon = true;
                                  for (final d in rawDetail) {
                                    if (d is Map) {
                                      final nm =
                                          d['nama_addon'] ??
                                          d['name'] ??
                                          d['nama'];
                                      if (nm != null) {
                                        final s = nm.toString().trim();
                                        if (s.isNotEmpty) addonNames.add(s);
                                      }
                                    }
                                  }
                                } else {
                                  final rawIds = item['addons'];
                                  if (rawIds is List) {
                                    if (rawIds.isNotEmpty)
                                      shouldHaveAddon = true;
                                    for (final a in rawIds) {
                                      int? id;
                                      if (a is int)
                                        id = a;
                                      else if (a is String)
                                        id = int.tryParse(a);
                                      if (id != null) {
                                        final n = _addonNameCache[id];
                                        if (n != null && n.trim().isNotEmpty)
                                          addonNames.add(n.trim());
                                      } else if (a is Map) {
                                        final nm =
                                            a['nama_addon'] ??
                                            a['name'] ??
                                            a['nama'];
                                        if (nm != null) {
                                          final s = nm.toString().trim();
                                          if (s.isNotEmpty) addonNames.add(s);
                                        }
                                      }
                                    }
                                  } else if (rawIds is String &&
                                      rawIds.trim().isNotEmpty) {
                                    shouldHaveAddon = true;
                                    for (final p in rawIds.split(',')) {
                                      final idCsv = int.tryParse(p.trim());
                                      if (idCsv != null) {
                                        final n = _addonNameCache[idCsv];
                                        if (n != null && n.trim().isNotEmpty)
                                          addonNames.add(n.trim());
                                      }
                                    }
                                  }
                                }
                                // Deduplicate
                                final seen = <String>{};
                                final filtered = <String>[];
                                for (final n in addonNames) {
                                  final l = n.toLowerCase();
                                  if (seen.add(l)) filtered.add(n);
                                }
                                final displayAddon = () {
                                  if (filtered.isEmpty) {
                                    if (shouldHaveAddon)
                                      return 'Addon: memuat...';
                                    return null; // no addon line
                                  }
                                  return 'Addon: ' + filtered.join(', ');
                                }();
                                final rawNote = (item['note'] ?? '')
                                    .toString()
                                    .trim();
                                final hasNote = rawNote.isNotEmpty;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              baseName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                            ),
                                            if (displayAddon != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  displayAddon,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            if (hasNote)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: displayAddon != null
                                                      ? 2
                                                      : 2,
                                                ),
                                                child: Text(
                                                  'Catatan: ' + rawNote,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: Color(0xFF602829),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '${item['qty']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // (Banner pembayaran dipindah ke atas nama resto)
                    // Tombol Detail Struk
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        height: 56,
                        child: CustomButtonKotak(
                          text: 'Detail Struk',
                          onPressed: () {
                            final bookingId =
                                (_tx?['booking_id']?.toString() ?? _bookingId)
                                    ?.trim();
                            final idTransaksi =
                                _tx?['id_transaksi'] ?? _idTransaksi;
                            if ((bookingId != null && bookingId.isNotEmpty) ||
                                idTransaksi != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReceiptPage(
                                    bookingId:
                                        (bookingId != null &&
                                            bookingId.isNotEmpty)
                                        ? bookingId
                                        : null,
                                    idTransaksi:
                                        (bookingId == null ||
                                                bookingId.isEmpty) &&
                                            idTransaksi is int
                                        ? idTransaksi
                                        : null,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Transaksi belum dimuat, coba lagi sesaat.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // (Snackbar sukses bukti pembayaran kini non-sticky & otomatis hilang)
                    //
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenericToast extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  const _GenericToast({
    Key? key,
    required this.message,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  State<_GenericToast> createState() => _GenericToastState();
}

class _GenericToastState extends State<_GenericToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
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

class _PaymentProofToast extends StatefulWidget {
  final VoidCallback onDismiss;
  const _PaymentProofToast({Key? key, required this.onDismiss})
    : super(key: key);

  @override
  State<_PaymentProofToast> createState() => _PaymentProofToastState();
}

class _PaymentProofToastState extends State<_PaymentProofToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF55B776),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bukti pembayaran terkirim',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
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

class _StepProcess {
  final String icon;
  final String label;
  final int stateIndex; // -1 = skipped
  _StepProcess({
    required this.icon,
    required this.label,
    required this.stateIndex,
  });
}

class _ProcessIcon extends StatelessWidget {
  final String icon;
  final bool isActive;
  final bool isDone;
  final double size;
  final double iconSize;
  const _ProcessIcon({
    required this.icon,
    required this.isActive,
    required this.isDone,
    this.size = 40,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isGrey =
        isDone || (!isActive && !isDone); // grey juga untuk future/inactive
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(vertical: 0),
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
      child: Stack(
        children: [
          Center(
            child: () {
              if (icon.startsWith('material:')) {
                final name = icon.substring('material:'.length);
                IconData data;
                switch (name) {
                  case 'storefront':
                    data = Icons.storefront;
                    break;
                  case 'store':
                    data = Icons.store;
                    break;
                  default:
                    data = Icons.help_outline;
                    break;
                }
                return Icon(
                  data,
                  size:
                      iconSize +
                      (name == 'store' || name == 'storefront' ? 2 : 0),
                  color: isGrey
                      ? Colors.grey.shade400
                      : const Color(0xFFB03056),
                );
              }
              if (icon.isNotEmpty) {
                return ColorFiltered(
                  colorFilter: isGrey
                      ? ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        ),
                  child: Image.asset(icon, width: iconSize, height: iconSize),
                );
              }
              return Icon(
                Icons.money,
                size: iconSize + 4,
                color: isGrey ? Colors.grey.shade400 : const Color(0xFFD53D3D),
              );
            }(),
          ),
        ],
      ),
    );
  }
}

String _formatRemaining(Duration d) {
  if (d.isNegative) return '0:00';
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _formatClock(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h.$m';
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 2.0;
    const dashSpace = 4.0;
    double startY = 0;
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = size.width;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// extension removed (unused)

// (Removed legacy _ReviewPageRoute; now using ReviewSheetRoute from review_page.dart)

// ---------------------------------------------------------------------------
// Timeout Dialog Widgets
// ---------------------------------------------------------------------------
class _TimeoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _TimeoutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [const Color(0xFFFDF3F5), const Color(0xFFFFF9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFB03056).withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB03056).withOpacity(0.18),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFB03056).withOpacity(0.90),
                      const Color(0xFFB03056).withOpacity(0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB03056).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mohon Maaf Waktu Pembayaran\nSudah Lewat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF602829),
                  height: 1.15,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mohon Buat Pesanan Kembali',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                  height: 1.25,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _DialogPrimaryButton(onTap: onConfirm, label: 'Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogPrimaryButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _DialogPrimaryButton({required this.onTap, required this.label});

  @override
  State<_DialogPrimaryButton> createState() => _DialogPrimaryButtonState();
}

class _DialogPrimaryButtonState extends State<_DialogPrimaryButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: _pressed
                ? [const Color(0xFFB03056), const Color(0xFFD53D3D)]
                : [const Color(0xFFD53D3D), const Color(0xFFB03056)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFB03056,
              ).withOpacity(_pressed ? 0.18 : 0.32),
              blurRadius: _pressed ? 10 : 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
