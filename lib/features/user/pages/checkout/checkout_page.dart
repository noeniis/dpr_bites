import 'package:dpr_bites/features/user/pages/checkout/checkout_process_page.dart';
import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart';
import 'alamat_pengantaran_dialog.dart';
import 'pembayaran_qris_dialog.dart';
import '../history/history_page.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/app/gradient_background.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Future<bool> _showCancelConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Anda ingin membatalkan pesanan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Iya'),
          ),
        ],
      ),
    );
    return result == true;
  }

  late List<Map<String, dynamic>> items;
  late int deliveryFee;
  late String restaurantName;
  late Map<String, dynamic> location;
  late Map<String, dynamic> payment;
  bool isDelivery = true;
  int? editingQtyIndex;
  int? editingNoteIndex;
  final Map<int, TextEditingController> _noteControllers = {};
  String selectedPayment = 'qris';

  @override
  void initState() {
    super.initState();
    final checkout = dummyCheckout;
    items = List<Map<String, dynamic>>.from(checkout['items'] as List);
    deliveryFee = checkout['deliveryFee'] as int;
    restaurantName = checkout['restaurantName'] as String;
    location = Map<String, dynamic>.from(checkout['location'] as Map);
    payment = Map<String, dynamic>.from(checkout['payment'] as Map);

    // Init note controllers
    for (int i = 0; i < items.length; i++) {
      _noteControllers[i] = TextEditingController(text: items[i]['note'] ?? '');
    }
  }

  int get subtotal =>
      items.fold(0, (a, b) => a + (b['price'] as int) * (b['qty'] as int));

  Future<void> _showDeleteDialog(int i) async {
    final itemName = items[i]['name'] ?? 'menu ini';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Apakah anda ingin menghapus $itemName dari pesanan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (result == true) {
      Navigator.of(context).pop();
    }
  }

  int get total => isDelivery ? subtotal + deliveryFee : subtotal;

  @override
  Widget build(BuildContext context) {
    // Untuk close qty editor jika tap di luar
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        bool needSet = false;
        if (editingQtyIndex != null) {
          editingQtyIndex = null;
          needSet = true;
        }
        if (editingNoteIndex != null) {
          // Simpan catatan
          items[editingNoteIndex!]['note'] =
              _noteControllers[editingNoteIndex!]?.text ?? '';
          editingNoteIndex = null;
          needSet = true;
        }
        if (needSet) setState(() {});
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.pink),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              restaurantName,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Card: Rangkuman Pesanan
              CustomEmptyCard(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rangkuman pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(items.length, (i) {
                        final item = items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      item['image'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        GestureDetector(
                                          onTap: () {
                                            if (editingNoteIndex == i) {
                                              // Simpan catatan dan keluar mode edit
                                              setState(() {
                                                items[i]['note'] =
                                                    _noteControllers[i]?.text ??
                                                    '';
                                                editingNoteIndex = null;
                                                editingQtyIndex = null;
                                              });
                                            } else {
                                              setState(() {
                                                editingNoteIndex = i;
                                                editingQtyIndex = i;
                                              });
                                            }
                                          },
                                          child: Text(
                                            editingNoteIndex == i
                                                ? 'Simpan'
                                                : 'Ubah',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        // Tampilkan catatan jika ada, kecuali sedang edit
                                        if ((item['note'] ?? '')
                                                .toString()
                                                .isNotEmpty &&
                                            editingNoteIndex != i)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                              right: 8,
                                            ),
                                            child: Text(
                                              item['note'],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFFB0B0B0),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item['price']
                                            .toString()
                                            .replaceAllMapped(
                                              RegExp(
                                                r'(\d{1,3})(?=(\d{3})+(?!\d))',
                                              ),
                                              (m) => '${m[1]}.',
                                            ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editingQtyIndex = i;
                                          });
                                        },
                                        child: editingQtyIndex == i
                                            ? Container(
                                                width: 54,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Color(0xFFD53D3D),
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                alignment: Alignment.center,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: () async {
                                                        if (items[i]['qty'] ==
                                                            1) {
                                                          await _showDeleteDialog(
                                                            i,
                                                          );
                                                        } else {
                                                          setState(() {
                                                            items[i]['qty']--;
                                                          });
                                                        }
                                                      },
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 16,
                                                        color: Color(
                                                          0xFFD53D3D,
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                          ),
                                                      child: Text(
                                                        '${item['qty']}',
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFFD53D3D,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          items[i]['qty']++;
                                                        });
                                                      },
                                                      child: const Icon(
                                                        Icons.add,
                                                        size: 16,
                                                        color: Color(
                                                          0xFFD53D3D,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color: Color(0xFFD53D3D),
                                                    width: 2,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${item['qty']}',
                                                  style: const TextStyle(
                                                    color: Color(0xFFD53D3D),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (editingNoteIndex == i)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    right: 8,
                                    left: 72,
                                  ),
                                  child: TextField(
                                    controller: _noteControllers[i],
                                    decoration: InputDecoration(
                                      hintText: 'Catatan untuk restoran',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFB0B0B0),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFB0B0B0),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    minLines: 1,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 13),
                                    onEditingComplete: () {
                                      setState(() {
                                        items[i]['note'] =
                                            _noteControllers[i]?.text ?? '';
                                        editingNoteIndex = null;
                                        editingQtyIndex = null;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(fontSize: 15),
                          ),
                          Text(
                            subtotal.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (m) => '${m[1]}.',
                            ),
                          ),
                        ],
                      ),
                      isDelivery
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ongkos kirim',
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  deliveryFee.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (m) => '${m[1]}.',
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Pengantaran / Pickup
              Row(
                children: [
                  Expanded(
                    child: CustomFilterChip(
                      label: 'Pengantaran',
                      selected: isDelivery,
                      onTap: () => setState(() => isDelivery = true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomFilterChip(
                      label: 'Pickup',
                      selected: !isDelivery,
                      onTap: () => setState(() => isDelivery = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Lokasi Pengantaran / Pickup
              InkWell(
                onTap: () async {
                  if (!isDelivery) return;
                  final result = await showDialog<Map<String, String>>(
                    context: context,
                    builder: (ctx) => AlamatPengantaranDialog(
                      initialNama: location['name'],
                      initialDetail: location['detail'],
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      location['name'] = result['nama'] ?? location['name'];
                      location['detail'] =
                          result['detail'] ?? location['detail'];
                    });
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD53D3D),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        location['icon'],
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDelivery ? location['name'] : restaurantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF602829),
                              ),
                            ),
                            Text(
                              isDelivery
                                  ? location['detail']
                                  : 'Lokasi restoran',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFFD53D3D)),
                    ],
                  ),
                ),
              ),
              // Pembayaran (QRIS & Tunai)
              InkWell(
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (ctx) {
                      return AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        padding: MediaQuery.of(ctx).viewInsets,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Pilih Metode Pembayaran',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ListTile(
                                leading: const Icon(
                                  Icons.qr_code,
                                  color: Color(0xFFD53D3D),
                                  size: 32,
                                ),
                                title: const Text(
                                  'QRIS',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: selectedPayment == 'qris'
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() => selectedPayment = 'qris');
                                  Navigator.of(ctx).pop();
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.money,
                                  color: Color(0xFFD53D3D),
                                  size: 32,
                                ),
                                title: const Text(
                                  'Tunai',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: selectedPayment == 'cash'
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() => selectedPayment = 'cash');
                                  Navigator.of(ctx).pop();
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD53D3D),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      selectedPayment == 'qris'
                          ? const Icon(
                              Icons.qr_code,
                              color: Color(0xFFD53D3D),
                              size: 28,
                            )
                          : const Icon(
                              Icons.money,
                              color: Color(0xFFD53D3D),
                              size: 28,
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedPayment == 'qris' ? 'Qris' : 'Tunai',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF602829),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFFD53D3D)),
                    ],
                  ),
                ),
              ),
              // Total Harga dan Tombol Pesan
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      total.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]}.',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 18),
                child: CustomButtonOval(
                  text: 'Pesan',
                  onPressed: () async {
                    bool batal = false;
                    if (selectedPayment == 'qris') {
                      // Tampilkan dialog QRIS
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) {
                          return WillPopScope(
                            onWillPop: () async {
                              final confirm = await _showCancelConfirmDialog();
                              if (confirm) {
                                Navigator.of(ctx).pop();
                                batal = true;
                              }
                              return false;
                            },
                            child: PembayaranQrisDialog(
                              onKonfirmasi: () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutProcessPage(),
                                  ),
                                );
                              },
                              onBatal: () async {
                                final confirm =
                                    await _showCancelConfirmDialog();
                                if (confirm) {
                                  Navigator.of(ctx).pop();
                                  batal = true;
                                }
                              },
                            ),
                          );
                        },
                      );
                    } else {
                      // Tunai: animasi bottom sheet konfirmasi
                      if (isDelivery) {
                        await showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (ctx) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.money,
                                    color: Color(0xFFD53D3D),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Pembayaran Tunai',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Siapkan uang sebesar Rp${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} kepada petugas yang mengantar makanan anda',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD53D3D),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CheckoutProcessPage(),
                                            ),
                                          );
                                        },
                                        child: const Text('Konfirmasi'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        await showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (ctx) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.money,
                                    color: Color(0xFFD53D3D),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Pembayaran Tunai',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Silakan bayar langsung ke kasir saat pesanan diantar atau diambil dengan total pembayaran Rp${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}.',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD53D3D),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CheckoutProcessPage(),
                                            ),
                                          );
                                        },
                                        child: const Text('Konfirmasi'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    }
                    if (batal) {
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                HistoryPage(initialFilter: 'dibatalkan'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              // ...lanjutan komponen lain (alamat, pembayaran, total, tombol pesan)
            ],
          ),
        ),
      ),
    );
  }
}
