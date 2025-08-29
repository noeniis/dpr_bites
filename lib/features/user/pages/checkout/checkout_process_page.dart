import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/features/user/pages/history/receipt_page.dart';
import 'package:dpr_bites/features/user/pages/checkout/chat_page.dart';
import 'package:dpr_bites/features/user/pages/checkout/pembayaran_qris_dialog.dart';

class CheckoutProcessPage extends StatefulWidget {
  final String? bookingId;
  final int? idTransaksi;
  const CheckoutProcessPage({Key? key, this.bookingId, this.idTransaksi})
    : super(key: key);

  @override
  State<CheckoutProcessPage> createState() => _CheckoutProcessPageState();
}

class _CheckoutProcessPageState extends State<CheckoutProcessPage> {
  Map<String, dynamic>? _tx;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true; // minimal usage via Offstage
  String? _error; // minimal usage via Offstage
  int _currentStep = 0; // 0..3
  bool _isPickup = false;
  late final String? _bookingId;
  late final int? _idTransaksi;
  int _pollCount = 0;
  String _metode = '';
  DateTime? _disiapkanStart; // waktu pertama kali masuk status disiapkan
  final Duration _prepDuration = const Duration(minutes: 15);
  Duration _remaining = const Duration(minutes: 15);
  bool _timerScheduled = false;
  DateTime?
  _selesaiAt; // waktu lokal ketika pertama kali status selesai terdeteksi (fallback jika backend belum kirim field khusus)
  DateTime?
  _firstFetchAt; // fallback waktu lokal pembuatan (approx) jika created_at tidak tersedia dari backend
  // status final dibatalkan/selesai hentikan polling
  bool get _finished =>
      _tx != null &&
      ['selesai', 'dibatalkan'].contains((_tx!['status'] ?? '').toString());
  bool _shownQris = false; // to avoid repeated dialog
  // Cache nama addon (id_addon -> nama_addon)
  final Map<int, String> _addonNameCache = {};
  int? _geraiId; // cache id gerai hasil resolve (backend mungkin belum kirim)
  String?
  _bookingCreatedAtDisplay; // cache format tanggal booking agar tidak hitung ulang tiap build

  Future<void> _resolveGeraiIdFromMenu(int idMenu) async {
    if (idMenu <= 0) return;
    // Coba beberapa endpoint potensial
    final candidates = [
      'http://10.0.2.2/dpr_bites_api/get_single_menu.php?id_menu=',
      'http://10.0.2.2/dpr_bites_api/get_menu_detail.php?id_menu=',
      'http://10.0.2.2/dpr_bites_api/get_menu_detail_user.php?id_menu=',
    ];
    for (final base in candidates) {
      if (_geraiId != null) break;
      final url = base + idMenu.toString();
      try {
        final resp = await http.get(
          Uri.parse(url),
          headers: const {'Accept': 'application/json'},
        );
        // ignore: avoid_print
        print('[GERAI RESOLVE TRY] url=$url code=${resp.statusCode}');
        if (resp.statusCode != 200) continue;
        final j = jsonDecode(resp.body);
        if (j is! Map) {
          // ignore: avoid_print
          print('[GERAI RESOLVE] response bukan Map');
          continue;
        }
        final success = j['success'];
        final data = j['data'];
        if (success == true && data is Map) {
          final g = data['id_gerai'];
          if (g != null) {
            final parsed = g is int ? g : int.tryParse(g.toString());
            if (parsed != null) {
              _geraiId = parsed;
              // ignore: avoid_print
              print(
                '[GERAI RESOLVE OK] id_menu=$idMenu -> id_gerai=$_geraiId via $url',
              );
            }
          }
        } else {
          // ignore: avoid_print
          print('[GERAI RESOLVE FAIL] success=$success body=${resp.body}');
        }
      } catch (e) {
        // ignore: avoid_print
        print('[GERAI RESOLVE EXC] $e');
      }
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final qp = <String, String>{};
      final bId = _bookingId;
      if (bId != null && bId.isNotEmpty) {
        qp['booking_id'] = bId;
      } else if (_idTransaksi != null) {
        qp['id_transaksi'] = _idTransaksi.toString();
      }
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_transaction_detail.php',
      ).replace(queryParameters: qp);
      final resp = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      // DEBUG: log raw response (hapus nanti jika sudah beres)
      // ignore: avoid_print
      print('[TX DEBUG] status=${resp.statusCode} body=${resp.body}');
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      final json = jsonDecode(resp.body);
      if (json is! Map || json['success'] != true) {
        throw Exception(
          json is Map ? (json['message'] ?? 'Gagal') : 'Respon tidak valid',
        );
      }
      final data = json['data'] as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();
      _metode = (data['metode_pembayaran'] ?? '').toString();
      _tx = data;
      _items = List<Map<String, dynamic>>.from(data['items'] as List);
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
      // Catat waktu mulai disiapkan untuk countdown
      if (status == 'disiapkan' && _disiapkanStart == null) {
        _disiapkanStart = DateTime.now();
        _remaining = _prepDuration;
        _scheduleCountdownTick();
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
      setState(() => _loading = false);
      _maybeShowQrisDialog();
      if (!_finished) _schedulePoll();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
    try {
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_addon.php?id_gerai=' +
            idGerai.toString(),
      );
      final resp = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        if (j is Map && j['success'] == true) {
          final addons = j['addons'];
          if (addons is List) {
            for (final a in addons) {
              if (a is Map) {
                final id = a['id_addon'];
                final name = a['nama_addon'];
                if (id != null && name != null) {
                  final intId = id is int
                      ? id
                      : int.tryParse(id.toString()) ?? -1;
                  if (intId > 0) {
                    _addonNameCache[intId] = name.toString();
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}
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
      final qrisPath = (_tx!['qris_path'] ?? '').toString();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return PembayaranQrisDialog(
            qrisImageUrl: qrisPath.isEmpty ? null : qrisPath,
            onKonfirmasi: (file) async {
              // Dialog sudah menutup dirinya sendiri di dalam PembayaranQrisDialog sebelum callback dipanggil.
              // Langsung lanjut upload menggunakan context parent tanpa mem-pop halaman ini.
              try {
                final bytes = await file.readAsBytes();
                final b64 = base64Encode(bytes);
                final resp = await http.post(
                  Uri.parse(
                    'http://10.0.2.2/dpr_bites_api/upload_payment_proof_user.php',
                  ),
                  headers: const {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'booking_id': _tx!['booking_id'],
                    'bukti_base64': 'data:image/png;base64,' + b64,
                  }),
                );
                if (resp.statusCode == 200) {
                  final j = jsonDecode(resp.body);
                  if (j is Map && j['success'] == true) {
                    if (mounted) {
                      await _fetch();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upload bukti gagal')),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('HTTP ${resp.statusCode} upload gagal'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error upload: $e')));
                }
              }
            },
            onBatal: () async {
              final confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (c) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFB03056),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Batalkan Pesanan?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF602829),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Apakah yakin ingin membatalkan pesanan ini?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF602829),
                                  ),
                                  child: const Text('Tidak'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB03056),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Ya, Batalkan'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              if (confirm == true) {
                try {
                  await http.post(
                    Uri.parse(
                      'http://10.0.2.2/dpr_bites_api/update_transaction_status.php',
                    ),
                    headers: const {
                      'Accept': 'application/json',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'booking_id': _tx!['booking_id'],
                      'new_status': 'dibatalkan',
                      'alasan': 'pembayaran dibatalkan',
                    }),
                  );
                } catch (_) {}
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          );
        },
      );
    }
  }

  void _schedulePoll() {
    if (!mounted) return;
    if (_finished) return;
    if (_pollCount > 120) return; // ~10 menit kalau interval 5s
    _pollCount++;
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _fetch();
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
        setState(() => _remaining = Duration.zero);
        return false;
      }
      setState(() => _remaining = remaining);
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
          label: _isPickup
              ? 'Makanan Siap untuk Diambil'
              : 'Makanan Lagi Disiapin',
          stateIndex: 1,
        ),
        _StepProcess(
          icon: _isPickup
              ? 'material:store'
              : 'lib/assets/images/iconDelivery.png',
          label: _isPickup ? 'Pick Up' : 'Makanan Dalam Perjalanan',
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
        label: _isPickup
            ? 'Makanan Siap untuk Diambil'
            : 'Makanan Lagi Disiapin',
        stateIndex: 2,
      ),
      _StepProcess(
        icon: _isPickup
            ? 'material:store'
            : 'lib/assets/images/iconDelivery.png',
        label: _isPickup ? 'Pick Up' : 'Makanan Dalam Perjalanan',
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
    }
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
    // cancelled & note prepared (not rendered to avoid layout change)
    final cancelled = _tx != null && (_tx!['status'] == 'dibatalkan');
    final cancellationNote = _tx != null
        ? (_tx!['catatan_pembatalan'] ?? '')
        : '';
    // Offstage widgets to reference variables so not flagged unused (no visible layout impact)
    final diagnostics = Offstage(
      offstage: true,
      child: Column(
        children: [
          if (_loading) const SizedBox.shrink(),
          if (_error != null) Text(_error!),
          if (cancelled) Text(cancellationNote),
        ],
      ),
    );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFB03056)),
            onPressed: () => Navigator.of(context).pop(),
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
                            children: List.generate(steps.length * 2 - 1, (i) {
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
                                                style: titleStyleBase.copyWith(
                                                  fontSize: narrow ? 16 : 18,
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
                                        final eta = DateTime.now().add(
                                          _remaining.isNegative
                                              ? Duration.zero
                                              : _remaining,
                                        );
                                        return SizedBox(
                                          width: double.infinity,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Estimasi',
                                                style: titleStyleBase.copyWith(
                                                  fontSize: narrow ? 14 : 16,
                                                  height: 1.1,
                                                ),
                                              ),
                                              // Pastikan tidak membungkus: pakai FittedBox agar turun ukuran bila tetap overflow
                                              FittedBox(
                                                alignment: Alignment.centerLeft,
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
                                                '${_formatClock(eta)} WIB',
                                                style: timeStyle,
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Diantar Dalam',
                                              style: titleStyleBase.copyWith(
                                                fontSize: narrow ? 16 : 18,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatRemaining(_remaining),
                                              style: timeStyle,
                                            ),
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
                        SizedBox(
                          height: 43,
                          child: AspectRatio(
                            aspectRatio: 2.6,
                            child: CustomButtonKotak(
                              text: 'Chat Resto',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      restaurantName: restaurantName,
                                    ),
                                  ),
                                );
                              },
                              backgroundColor: null,
                              textColor: Colors.white.withOpacity(0.55),
                            ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        final m = _metode.trim().toLowerCase();
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
                                  if (rawIds.isNotEmpty) shouldHaveAddon = true;
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                  if ((_tx?['status'] == 'konfirmasi_pembayaran') &&
                      ((_tx?['bukti_pembayaran'] ?? '').toString().isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF55B776),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle, color: Color(0xFF55B776)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bukti pembayaran terkirim',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF256235),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if ((_tx?['status'] == 'konfirmasi_pembayaran') &&
                      ((_tx?['bukti_pembayaran'] ?? '').toString().isNotEmpty))
                    const SizedBox(height: 16),
                  diagnostics,
                ],
              ),
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
