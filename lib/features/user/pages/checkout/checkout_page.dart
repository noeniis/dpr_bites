import 'package:dpr_bites/features/user/pages/checkout/checkout_process_page.dart';
import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart';
import 'package:dpr_bites/common/data/dummy_address.dart';
import 'package:dpr_bites/common/data/dummy_carts.dart';
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
  String selectedPayment = 'qris';
  DummyAddress? selectedAddress;

  @override
  void initState() {
    super.initState();
    final checkout = dummyCheckout;
    // Ambil 3 menu dari dummy_carts (lintas restoran jika perlu)
    final List<Map<String, dynamic>> picked = [];
    for (final cart in dummyCarts) {
      final menus = cart['menus'] as List<dynamic>;
      for (final m in menus) {
        if (picked.length < 3) {
          picked.add(Map<String, dynamic>.from(m as Map));
        }
      }
      if (picked.length >= 3) break;
    }
    items = picked;
    // Judul pakai restoran pertama (fallback ke dummyCheckout bila kosong)
    restaurantName = (dummyCarts.isNotEmpty
        ? dummyCarts.first['restaurantName'] as String
        : checkout['restaurantName'] as String);
    // Data lain tetap dari dummyCheckout agar alur lain tidak berubah
    deliveryFee = checkout['deliveryFee'] as int;
    location = Map<String, dynamic>.from(checkout['location'] as Map);
    payment = Map<String, dynamic>.from(checkout['payment'] as Map);

    // Set default delivery address from dummy addresses
    try {
      selectedAddress = dummyAddresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      if (dummyAddresses.isNotEmpty) {
        selectedAddress = dummyAddresses.first;
      }
    }

    // No inline note editors on checkout; editing via modal sheet like Cart
  }

  int get subtotal => items.fold(0, (a, b) {
    final base = (b['price'] is num) ? (b['price'] as num).toInt() : 0;
    final qty = (b['qty'] is num) ? (b['qty'] as num).toInt() : 1;
    final add = _addonTotalFor(b);
    return a + (base + add) * qty;
  });

  int _addonTotalFor(Map<String, dynamic> item) {
    try {
      final List addons = (item['addon'] as List?) ?? const [];
      if (addons.isEmpty) {
        return (item['addonPrice'] is num)
            ? (item['addonPrice'] as num).toInt()
            : 0;
      }
      final List<Map<String, dynamic>> options =
          ((item['addonOptions'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      int sum = 0;
      for (final a in addons) {
        final opt = options.firstWhere(
          (o) => o['label'] == a,
          orElse: () => const {},
        );
        final p = (opt['price'] is num) ? (opt['price'] as num).toInt() : 0;
        sum += p;
      }
      if (sum == 0) {
        return (item['addonPrice'] is num)
            ? (item['addonPrice'] as num).toInt()
            : 0;
      }
      return sum;
    } catch (_) {
      return (item['addonPrice'] is num)
          ? (item['addonPrice'] as num).toInt()
          : 0;
    }
  }

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

  Future<void> _showEditMenuSheet(int index) async {
    final Map<String, dynamic> menu = items[index];
    final TextEditingController noteController = TextEditingController(
      text: menu['note'] ?? '',
    );
    List<String> selectedAddons = [];
    if (menu['addon'] is String && (menu['addon'] as String).isNotEmpty) {
      selectedAddons = [menu['addon'] as String];
    } else if (menu['addon'] is List) {
      selectedAddons = List<String>.from(menu['addon'] as List);
    }
    final List addonOptions = menu['addonOptions'] ?? [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.95,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              menu['image'] ?? '',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          menu['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (menu['desc'] != null &&
                            (menu['desc'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              menu['desc'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (addonOptions.isNotEmpty) ...[
                          const Text(
                            'Pilih Addon',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...addonOptions.map<Widget>((opt) {
                            return CheckboxListTile(
                              value: selectedAddons.contains(opt['label']),
                              title: Text(
                                '${opt['label']} ${opt['price'] > 0 ? '(+Rp${(opt['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')})' : ''}',
                              ),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    selectedAddons.add(opt['label']);
                                  } else {
                                    selectedAddons.remove(opt['label']);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
                          const SizedBox(height: 12),
                        ],
                        const Text(
                          'Catatan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Tulis catatan untuk menu ini',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFD53D3D),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFD53D3D),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFD53D3D),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButtonKotak(
                            text: 'Simpan',
                            onPressed: () {
                              int totalAddonPrice = 0;
                              for (var opt in addonOptions) {
                                if (selectedAddons.contains(opt['label'])) {
                                  totalAddonPrice += opt['price'] as int;
                                }
                              }
                              setState(() {
                                items[index]['note'] = noteController.text;
                                items[index]['addon'] = selectedAddons;
                                items[index]['addonPrice'] = totalAddonPrice;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

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
        // No inline note editor here
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                          onTap: () => _showEditMenuSheet(i),
                                          child: const Text(
                                            'Ubah',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        // Addon kecil di bawah "Ubah" (dengan harga)
                                        Builder(
                                          builder: (context) {
                                            final List addons =
                                                (item['addon'] as List?) ??
                                                const [];
                                            if (addons.isEmpty)
                                              return const SizedBox.shrink();
                                            final List<Map<String, dynamic>>
                                            options =
                                                ((item['addonOptions']
                                                            as List?) ??
                                                        const [])
                                                    .map(
                                                      (e) =>
                                                          Map<
                                                            String,
                                                            dynamic
                                                          >.from(e as Map),
                                                    )
                                                    .toList();
                                            String withPrice(dynamic label) {
                                              final opt = options.firstWhere(
                                                (o) => o['label'] == label,
                                                orElse: () => const {},
                                              );
                                              final p = (opt['price'] is num)
                                                  ? (opt['price'] as num)
                                                        .toInt()
                                                  : 0;
                                              final pStr = p
                                                  .toString()
                                                  .replaceAllMapped(
                                                    RegExp(
                                                      r'(\d{1,3})(?=(\d{3})+(?!\d))',
                                                    ),
                                                    (m) => '${m[1]}.',
                                                  );
                                              return p >= 0
                                                  ? '$label (+Rp$pStr)'
                                                  : '$label';
                                            }

                                            final text = addons
                                                .map(withPrice)
                                                .join(', ');
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                                right: 8,
                                              ),
                                              child: Text(
                                                text,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF9E9E9E),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          },
                                        ),
                                        // Baris catatan selalu tampil
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                            right: 8,
                                          ),
                                          child: Text(
                                            'catatan: ' +
                                                (((item['note'] ?? '')
                                                            as String)
                                                        .trim()
                                                        .isEmpty
                                                    ? '-'
                                                    : (item['note'] as String)),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFB0B0B0),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final base = (item['price'] is num)
                                              ? (item['price'] as num).toInt()
                                              : 0;
                                          final addon = _addonTotalFor(item);
                                          final qty = (item['qty'] is num)
                                              ? (item['qty'] as num).toInt()
                                              : 1;
                                          final lineTotal =
                                              (base + addon) * qty;
                                          final formatted = lineTotal
                                              .toString()
                                              .replaceAllMapped(
                                                RegExp(
                                                  r'(\d{1,3})(?=(\d{3})+(?!\d))',
                                                ),
                                                (m) => '${m[1]}.',
                                              );
                                          return Text(
                                            'Rp$formatted',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 10),
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
                              // Inline note editor removed; editing via modal sheet
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
                            'Rp${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                                  'Rp${deliveryFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                  await showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (ctx) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: SizedBox(
                                  width: 40,
                                  child: Divider(thickness: 3),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pilih Alamat Pengantaran',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Flexible(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: dummyAddresses.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (ctx, i) {
                                    final a = dummyAddresses[i];
                                    final bool isSelected =
                                        selectedAddress?.namaGedung ==
                                            a.namaGedung &&
                                        selectedAddress?.namaPenerima ==
                                            a.namaPenerima &&
                                        selectedAddress?.noHp == a.noHp;
                                    return InkWell(
                                      onTap: () {
                                        setState(() => selectedAddress = a);
                                        Navigator.of(ctx).pop();
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFD53D3D)
                                                : const Color(0xFFB0B0B0),
                                            width: isSelected ? 1.8 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              color: Color(0xFFD53D3D),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    a.namaGedung,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${a.namaPenerima} - ${a.noHp}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    a.detailPengantaran,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      isDelivery
                          ? const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFFD53D3D),
                              size: 28,
                            )
                          : Image.asset(
                              location['icon'],
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isDelivery && selectedAddress != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedAddress!.namaGedung,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF602829),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${selectedAddress!.namaPenerima} - ${selectedAddress!.noHp}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedAddress!.detailPengantaran,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurantName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF602829),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Lokasi restoran',
                                    style: TextStyle(
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
                      'Rp${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFD53D3D,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CheckoutProcessPage(),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFD53D3D,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CheckoutProcessPage(),
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
