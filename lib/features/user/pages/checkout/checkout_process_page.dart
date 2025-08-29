import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart';
import 'package:dpr_bites/common/data/dummy_orders.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/features/user/pages/history/receipt_page.dart';
import 'package:dpr_bites/features/user/pages/checkout/chat_page.dart';
import 'package:dpr_bites/features/user/pages/checkout/pembayaran_qris_dialog.dart';

class CheckoutProcessPage extends StatefulWidget {
  final String? bookingId;
  final int? idTransaksi;
  const CheckoutProcessPage({Key? key, this.bookingId, this.idTransaksi}) : super(key: key);

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
  DateTime? _selesaiAt; // waktu lokal ketika pertama kali status selesai terdeteksi (fallback jika backend belum kirim field khusus)
  // status final dibatalkan/selesai hentikan polling
  bool get _finished => _tx != null && ['selesai','dibatalkan'].contains((_tx!['status']??'').toString());
  bool _shownQris = false; // to avoid repeated dialog

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _idTransaksi = widget.idTransaksi;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(()=>_loading=true);
    try {
  final qp = <String,String>{};
  final bId = _bookingId; if(bId != null && bId.isNotEmpty){ qp['booking_id']=bId; }
  else if(_idTransaksi!=null){ qp['id_transaksi']=_idTransaksi.toString(); }
  final uri = Uri.parse('http://10.0.2.2/dpr_bites_api/get_transaction_detail.php').replace(queryParameters: qp);
      final resp = await http.get(uri, headers: const {'Accept':'application/json'});
      if(resp.statusCode!=200){ throw Exception('HTTP ${resp.statusCode}'); }
      final json = jsonDecode(resp.body);
      if(json is! Map || json['success']!=true){ throw Exception(json is Map ? (json['message']??'Gagal') : 'Respon tidak valid'); }
      final data = json['data'] as Map<String,dynamic>;
      final status = (data['status']??'').toString();
      _metode = (data['metode_pembayaran']??'').toString();
      _tx = data;
      _items = List<Map<String,dynamic>>.from(data['items'] as List);
      _isPickup = (data['jenis_pengantaran']??'')=='pickup';
      _currentStep = _mapStatusToStep(status, _isPickup, _metode);
      // Catat waktu mulai disiapkan untuk countdown
      if(status=='disiapkan' && _disiapkanStart==null){
        _disiapkanStart = DateTime.now();
        _remaining = _prepDuration;
        _scheduleCountdownTick();
      }
      // Catat waktu selesai lokal bila status selesai muncul pertama kali (gunakan field backend jika tersedia)
      if(status=='selesai' && _selesaiAt==null){
        // Jika backend menyediakan 'waktu_selesai' atau 'completed_at', coba parse
        DateTime? backendDone;
        for(final key in ['waktu_selesai','completed_at','tanggal_selesai','updated_at']){
          final v = data[key];
            if(v is String && v.trim().isNotEmpty){
              try { backendDone = DateTime.parse(v); break; } catch(_){ }
            }
        }
        _selesaiAt = backendDone ?? DateTime.now();
      }
      setState(()=>_loading=false);
  _maybeShowQrisDialog();
      if(!_finished) _schedulePoll();
    } catch(e){
      setState(() { _error = e.toString(); _loading=false; });
    }
  }

  void _maybeShowQrisDialog(){
    if(!mounted) return;
    if(_shownQris) return;
    if(_tx==null) return;
    final status = (_tx!['status']??'').toString();
    final metode = (_tx!['metode_pembayaran']??'').toString();
    if(status=='konfirmasi_pembayaran' && metode=='qris'){
      _shownQris = true;
      final qrisPath = (_tx!['qris_path']??'').toString();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx){
          return PembayaranQrisDialog(
            qrisImageUrl: qrisPath.isEmpty ? null : qrisPath,
            onKonfirmasi: (file) async {
              // Dialog sudah menutup dirinya sendiri di dalam PembayaranQrisDialog sebelum callback dipanggil.
              // Langsung lanjut upload menggunakan context parent tanpa mem-pop halaman ini.
              try {
                final bytes = await file.readAsBytes();
                final b64 = base64Encode(bytes);
                final resp = await http.post(
                  Uri.parse('http://10.0.2.2/dpr_bites_api/upload_payment_proof_user.php'),
                  headers: const {'Accept':'application/json','Content-Type':'application/json'},
                  body: jsonEncode({
                    'booking_id': _tx!['booking_id'],
                    'bukti_base64': 'data:image/png;base64,'+b64,
                  })
                );
                if(resp.statusCode==200){
                  final j=jsonDecode(resp.body);
                  if(j is Map && j['success']==true){
                    if(mounted){ await _fetch(); }
                  } else {
                    if(mounted){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload bukti gagal'))); }
                  }
                } else {
                  if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('HTTP ${resp.statusCode} upload gagal'))); }
                }
              } catch(e){
                if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error upload: $e'))); }
              }
            },
            onBatal: () async {
              final confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (c){
                  return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal:22, vertical:24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Color(0xFFB03056)),
                          const SizedBox(height: 14),
                          const Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize:18, color: Color(0xFF602829))),
                          const SizedBox(height: 8),
                          const Text('Apakah yakin ingin membatalkan pesanan ini?', textAlign: TextAlign.center, style: TextStyle(fontSize:14,color: Colors.black87,height:1.3)),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: ()=>Navigator.pop(c,false),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF602829)),
                                  child: const Text('Tidak'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: ()=>Navigator.pop(c,true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB03056),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical:12),
                                  ),
                                  child: const Text('Ya, Batalkan'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }
              );
              if(confirm==true){
                try{
                  await http.post(Uri.parse('http://10.0.2.2/dpr_bites_api/update_transaction_status.php'),
                    headers: const {'Accept':'application/json','Content-Type':'application/json'},
                    body: jsonEncode({
                      'booking_id': _tx!['booking_id'],
                      'new_status':'dibatalkan',
                      'alasan':'pembayaran dibatalkan',
                    }),
                  );
                }catch(_){ }
                if(mounted){ Navigator.of(context).pop(); }
              }
            },
          );
        }
      );
    }
  }

  void _schedulePoll(){
    if(!mounted) return; if(_finished) return; if(_pollCount>120) return; // ~10 menit kalau interval 5s
    _pollCount++;
    Future.delayed(const Duration(seconds:5), () { if(mounted) _fetch(); });
  }

  int _mapStatusToStep(String status, bool pickup, String metode){
    // Jika metode cash: lewati konfirmasi_pembayaran -> langkah index bergeser
    // Langkah definisi (untuk qris): 0 konfirmasi resto,1 konfirmasi pembayaran,2 disiapkan,3 antar/pickup
    // Untuk cash: 0 konfirmasi resto,1 disiapkan,2 antar/pickup (kita map supaya UI tetap 4 slot tapi step 1 (pembayaran) akan disabled/transparan)
    // NOTE: Untuk status 'selesai' kita geser index +1 agar step terakhir dianggap sudah DONE (warna abu-abu) bukan current highlight.
    switch(status){
      case 'konfirmasi_ketersediaan': return 0;
      case 'konfirmasi_pembayaran': return metode=='cash' ? 0 : 1; // cash tidak menggunakan status ini seharusnya
      case 'disiapkan': return metode=='cash' ? 1 : 2;
      case 'diantar': return metode=='cash' ? 2 : 3;
      case 'pickup': return metode=='cash' ? 2 : 3;
      case 'selesai': return metode=='cash' ? 3 : 4; // di luar range realIndex agar last step jadi isDone (grey)
      case 'dibatalkan': return 0;
      default: return 0;
    }
  }

  void _scheduleCountdownTick(){
    if(_timerScheduled) return; // single chain
    _timerScheduled = true;
    Future.doWhile(() async {
      if(!mounted) return false;
      if(_disiapkanStart==null) return false;
      final elapsed = DateTime.now().difference(_disiapkanStart!);
      final remaining = _prepDuration - elapsed;
      if(remaining <= Duration.zero){
        setState(()=>_remaining = Duration.zero);
        return false;
      }
      setState(()=>_remaining = remaining);
      await Future.delayed(const Duration(seconds:1));
      return true;
    });
  }

  List<_StepProcess> _buildSteps(){
    final isCash = _metode=='cash';
    return [
      _StepProcess(
        icon: 'lib/assets/images/iconCheck.png',
        label: 'Menunggu Konfirmasi Resto',
        stateIndex: 0,
      ),
      _StepProcess(
        icon: '',
        label: 'Konfirmasi Pembayaran',
        stateIndex: isCash ? -1 : 1, // -1 menandakan disabled / dilewati
      ),
      _StepProcess(
        icon: 'lib/assets/images/spatulaknife.png',
        label: _isPickup ? 'Makanan Siap untuk Diambil' : 'Makanan Lagi Disiapin',
        stateIndex: isCash ? 1 : 2,
      ),
      _StepProcess(
        icon: _isPickup ? '' : 'lib/assets/images/iconDelivery.png',
        label: _isPickup ? 'Pick Up' : 'Makanan Dalam Perjalanan',
        stateIndex: isCash ? 2 : 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Fallback dummy jika belum fetch agar struktur UI utuh
    final restaurantName = (_tx!=null ? _tx!['restaurantName'] : (dummyCheckout['restaurantName']))?.toString() ?? '';
    final locationSeller = _tx!=null ? (_tx!['locationSeller']??'') : (dummyCheckout['locationSeller']??'');
  final locationBuyer = _tx!=null ? (_tx!['locationBuyer']??'') : (dummyCheckout['locationBuyer']??'');
  final buildingNameBuyer = _tx!=null ? (_tx!['buildingNameBuyer']??'') : '';
    final locationDetail = _isPickup ? locationSeller : locationBuyer;
    final items = _items.isNotEmpty ? _items : (List<Map<String,dynamic>>.from(dummyCheckout['items'] as List));
  final steps = _buildSteps();
  // cancelled & note prepared (not rendered to avoid layout change)
  final cancelled = _tx!=null && (_tx!['status']=='dibatalkan');
    final cancellationNote = _tx!=null ? (_tx!['catatan_pembatalan']??'') : '';
    // Offstage widgets to reference variables so not flagged unused (no visible layout impact)
  final diagnostics = Offstage(
      offstage: true,
      child: Column(children:[
        if(_loading) const SizedBox.shrink(),
        if(_error!=null) Text(_error!),
        if(cancelled) Text(cancellationNote),
      ]),
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
                              final isSkipped = step.stateIndex==-1;
                              // Determine real active/done relative to _currentStep & stateIndex mapping
                              final realIndex = step.stateIndex;
                              final isCurrent = realIndex==_currentStep && realIndex>=0;
                              final isDone = realIndex>=0 && realIndex < _currentStep;
                              return Opacity(
                                opacity: isSkipped ? 0.2 : 1,
                                child: _ProcessIcon(
                                  icon: step.icon,
                                  isActive: !isSkipped && (isDone || isCurrent),
                                  isDone: isDone,
                                  size: isCurrent ? 54 : 40,
                                  iconSize: isCurrent ? 34 : 24,
                                ),
                              );
                            } else {
                              return Container(
                                width: 2,
                                height: 32,
                                child: CustomPaint(painter: _DashedLinePainter()),
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
                                final skipped = realIndex==-1;
                                // Bila _currentStep melampaui jumlah step (misal selesai -> 4) maka tidak ada current di daftar, semua <= currentStep menjadi done
                                final isCurrent = realIndex==_currentStep && realIndex>=0 && realIndex < steps.length;
                                final isDone = realIndex>=0 && realIndex < _currentStep && realIndex < steps.length;
                                final isFuture = realIndex>_currentStep || realIndex==-1;
                                Color color;
                                if(skipped){
                                  color = Colors.grey.withOpacity(0.35);
                                } else if(isCurrent){
                                  color = const Color(0xFFB03056); // highlight
                                } else if(isDone){
                                  color = Colors.grey; // completed greyed
                                } else if(isFuture){
                                  color = Colors.grey.withOpacity(0.55); // future dimmed
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
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
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
                        if(_currentStep >= (_metode=='cash'?1:2))
                          SizedBox(
                            width: 170, // lebar tetap agar kolom label tidak terhimpit
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const SizedBox(height: 80),
                                  LayoutBuilder(builder: (context, cons){
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
                                    final statusNow = (_tx?['status']??'').toString();
                                    if(statusNow=='selesai'){
                                      return SizedBox(
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Pesanan Selesai', style: titleStyleBase.copyWith(fontSize: narrow?16:18)),
                                            const SizedBox(height: 4),
                                            Text('${_formatClock(_selesaiAt ?? DateTime.now())} WIB', style: timeStyle),
                                          ],
                                        ),
                                      );
                                    } else if(statusNow=='diantar' || statusNow=='pickup'){
                                      final eta = DateTime.now().add(_remaining.isNegative? Duration.zero : _remaining);
                                      return SizedBox(
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Estimasi', style: titleStyleBase.copyWith(fontSize: narrow?14:16,height:1.1)),
                                            // Pastikan tidak membungkus: pakai FittedBox agar turun ukuran bila tetap overflow
                                            FittedBox(
                                              alignment: Alignment.centerLeft,
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'Pesanan Diterima',
                                                maxLines: 1,
                                                softWrap: false,
                                                style: titleStyleBase.copyWith(fontSize: narrow?14:16,height:1.1),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('${_formatClock(eta)} WIB', style: timeStyle),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Diantar Dalam', style: titleStyleBase.copyWith(fontSize: narrow?16:18)),
                                          const SizedBox(height: 4),
                                          Text(_formatRemaining(_remaining), style: timeStyle),
                                        ],
                                      );
                                    }
                                  }),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Nama resto dan chat
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF602829),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                              backgroundColor: null, // pakai gradient default
                              textColor: Colors.white.withOpacity(0.55),
                              // Opacity gradient diatur di CustomButtonKotak
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
                            Row(
                              children: [
                                _isPickup
                                    ? Icon(
                                        Icons.store,
                                        size: 36,
                                        color: Color(0xFFD53D3D),
                                      )
                                    : Image.asset(
                                        'lib/assets/images/iconDelivery.png',
                                        width: 36,
                                        height: 36,
                                      ),
                                const SizedBox(width: 10),
                                Text(
                                  _isPickup ? 'Pick Up' : 'Pesan Antar',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 21,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      const Text(
                                        'Alamat Antar',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        [
                                          if(!_isPickup && buildingNameBuyer.toString().isNotEmpty) buildingNameBuyer,
                                          locationDetail is String ? locationDetail : locationDetail.toString()
                                        ].join(!_isPickup && buildingNameBuyer.toString().isNotEmpty ? ' - ' : ''),
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
                            const SizedBox(height: 10),
                            const Text(
                              'Catatan:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              items.any((e) => (e['note'] ?? '').isNotEmpty)
                                  ? items
                                        .map((e) => e['note'])
                                        .where(
                                          (n) =>
                                              n != null &&
                                              n.toString().isNotEmpty,
                                        )
                                        .join(', ')
                                  : '-',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
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
                            const Text(
                              'Pesanan Kamu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FractionallySizedBox(
                              widthFactor: 1,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0x47000000), // 28% opacity
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...items.map(
                              (item) => Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      (item['name'] ?? item['menu'] ?? '')
                                          .toString(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
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
                            ),
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
                          // Cari order yang statusnya 'berlangsung' dari dummyOrders
                          Map<String, dynamic>? ongoingOrder;
                          try {
                            ongoingOrder = dummyOrders.firstWhere(
                              (order) => order['status'] == 'berlangsung',
                            );
                          } catch (e) {
                            ongoingOrder = null;
                          }
                          if (ongoingOrder != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReceiptPage(order: ongoingOrder!),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tidak ada pesanan yang sedang berlangsung.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if((_tx?['status']=='konfirmasi_pembayaran') && ((_tx?['bukti_pembayaran']??'').toString().isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal:24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF55B776), width: 1),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle, color: Color(0xFF55B776)),
                            SizedBox(width: 10),
                            Expanded(child: Text('Bukti pembayaran terkirim', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF256235))))
                          ],
                        ),
                      ),
                    ),
                  if((_tx?['status']=='konfirmasi_pembayaran') && ((_tx?['bukti_pembayaran']??'').toString().isNotEmpty)) const SizedBox(height: 16),
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
  final isGrey = isDone || (!isActive && !isDone); // grey juga untuk future/inactive
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
            child: icon.isNotEmpty
                ? ColorFiltered(
                    colorFilter: isGrey
                        ? ColorFilter.mode(
                            Colors.grey.shade400,
                            BlendMode.srcIn,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                    child: Image.asset(icon, width: iconSize, height: iconSize),
                  )
                : Icon(
                    Icons.money,
                    size: iconSize + 4,
                    color: isGrey ? Colors.grey.shade400 : Color(0xFFD53D3D),
                  ),
          ),
        ],
      ),
    );
  }
}

String _formatRemaining(Duration d){
  if(d.isNegative) return '0:00';
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2,'0')}';
}

String _formatClock(DateTime dt){
  final h = dt.hour.toString().padLeft(2,'0');
  final m = dt.minute.toString().padLeft(2,'0');
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
