import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart';
import 'package:dpr_bites/common/data/address_store.dart';
import 'package:dpr_bites/features/user/pages/address/address_page.dart';
import 'checkout_process_page.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/features/user/services/checkout_page_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<Map<String, dynamic>> items = [];
  int deliveryFee = 0;
  String restaurantName = '';
  Map<String, dynamic> location = {};
  Map<String, dynamic> payment = {};
  String? qrisPath;
  double? geraiLat;
  double? geraiLng;
  bool isDelivery = true;
  int? editingQtyIndex;
  String selectedPayment = 'qris';
  Map<String, dynamic>? selectedAddress;
  int? selectedAddressId;
  late final AddressStore _addressStore;
  bool _loading = true;
  String? _error;
  bool _noSelectionMatch = false;
  bool _retryAfterMismatch = false;
  List<int> _missingSelectedIds = [];
  int _geraiId = 0;
  List<int> _selectedCartItemIds = [];
  bool _didFetch = false;
  bool _cartDirty = false;
  bool _creatingTransaction = false; // guard to prevent double tap Pesan

  Future<void> _prefetchSelectedItemsDetail() async {
    if (_selectedCartItemIds.isEmpty) return; // hanya saat dari cart
    await CheckoutPageService.prefetchSelectedItemsDetail(items: items);
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['geraiId'] != null) {
        _geraiId = int.tryParse(args['geraiId'].toString()) ?? 0;
        final rawSel = args['selectedCartItemIds'];
        if (rawSel is List) {
          _selectedCartItemIds = rawSel
              .map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList();
        }
      }
      debugPrint('[CHECKOUT] init geraiId=$_geraiId sel=$_selectedCartItemIds');
      _fetchCheckoutData();
      _didFetch = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // fallback location & payment dari dummy agar UI tetap konsisten
    final checkout = dummyCheckout;
    location = Map<String, dynamic>.from(checkout['location'] as Map);
    payment = Map<String, dynamic>.from(checkout['payment'] as Map);
    _addressStore = AddressStore.instance;
    _addressStore.addListener(_onAddressChanged);
    // Populate selectedAddress awal jika sudah ada
    _onAddressChanged();
  }

  Future<void> _fetchCheckoutData() async {
    setState(() {
      _loading = true;
      _error = null;
      _noSelectionMatch = false;
    });
    try {
      final result = await CheckoutPageService.fetchCheckoutData(
        geraiId: _geraiId,
        selectedCartItemIds: _selectedCartItemIds,
      );
      if (!result.success) {
        _error = 'Gagal memuat';
      } else {
        restaurantName = result.restaurantName;
        deliveryFee = result.deliveryFee;
        qrisPath = result.qrisPath;
        geraiLat = result.latitude;
        geraiLng = result.longitude;
        items = result.items;
        selectedAddress = result.address;
        selectedAddressId = result.selectedAddressId;
        _noSelectionMatch = result.noSelectionMatch;
        _missingSelectedIds = result.missingSelectedIds;
        if (!_noSelectionMatch) {
          await _prefetchSelectedItemsDetail();
        } else if (!_retryAfterMismatch) {
          _retryAfterMismatch = true;
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _fetchCheckoutData();
          });
        }
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  int get subtotal => items.fold(0, (a, b) {
    // Jika API sudah hitung subtotal per item (misal field subtotal) gunakan itu
    if (b['subtotal'] is num) {
      return a + (b['subtotal'] as num).toInt();
    }
    final base = (b['price'] is num) ? (b['price'] as num).toInt() : 0;
    final qty = (b['qty'] is num) ? (b['qty'] as num).toInt() : 1;
    final add = _addonTotalFor(b);
    return a + (base + add) * qty;
  });

  int _addonTotalFor(Map<String, dynamic> item) {
    // Hanya untuk menampilkan breakdown harga addon; backend sudah include addon dalam harga_satuan & subtotal.
    try {
      final List<Map<String, dynamic>> options =
          ((item['addonOptions'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      final List labels = (item['addon'] as List?) ?? const [];
      int sum = 0;
      for (final lab in labels) {
        final opt = options.firstWhere(
          (o) => o['label'] == lab,
          orElse: () => const {},
        );
        final p = (opt['price'] is num) ? (opt['price'] as num).toInt() : 0;
        sum += p;
      }
      return sum;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _syncItemQtyToServer(Map<String, dynamic> item) async {
    if (item['__busy'] == true) return; // debounce
    item['__busy'] = true;
    if (mounted) setState(() {});
    try {
      final res = await CheckoutPageService.syncItemQtyToServer(
        item: item,
        geraiId: _geraiId,
      );
      if (res.updatedItem != null) {
        final it = res.updatedItem!;
        item['subtotal'] = it['subtotal'];
        item['harga_satuan'] = it['harga_satuan'];
        if (it['addons'] is List) {
          item['addonIds'] = (it['addons'] as List)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e > 0)
              .toList();
        }
        _cartDirty = true;
        if (mounted) setState(() {});
      }
    } catch (_) {
    } finally {
      item['__busy'] = false;
      if (mounted) setState(() {});
    }
  }

  // _showDeleteDialog dihapus: kini pengurangan qty dari 1 langsung menghapus item.

  Future<void> _deleteItem(int index, {bool navigateBackAfter = false}) async {
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    final menuId =
        item['menu_id'] ?? item['menuId'] ?? item['id_menu'] ?? item['id'];
    if (menuId == null) return;
    _cartDirty = true;
    final ok = await CheckoutPageService.deleteItem(
      item: item,
      geraiId: _geraiId,
    );
    if (ok) {
      items.removeAt(index);
      if (mounted) setState(() {});
    }
    if (navigateBackAfter) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    // Jika sudah tidak ada item, otomatis kembali
    if (items.isEmpty && mounted) {
      Navigator.of(context).pop(true); // pop dengan dirty untuk refresh
    }
  }

  Future<bool> _confirmDeleteItem(Map<String, dynamic> item) async {
    final name = (item['name'] ?? 'Item').toString();
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Hapus',
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (ctx, anim, __, ___) {
            final curved = CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return Opacity(
              opacity: curved.value,
              child: Transform.scale(
                scale: 0.95 + 0.05 * curved.value,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(ctx).size.width * 0.78,
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFCE2E2), Color(0xFFF8D1D1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFD53D3D),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Hapus Item?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C2C2C),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yakin ingin menghapus \"$name\" dari keranjang? Tindakan ini tidak bisa dibatalkan.',
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: Color(0xFF5A5A5A),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF444444),
                                    side: const BorderSide(
                                      color: Color(0xFFE4E4E4),
                                      width: 1.4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text(
                                    'Batal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD53D3D),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }

  int get total => isDelivery ? subtotal + deliveryFee : subtotal;

  Future<void> _showEditMenuSheet(int index) async {
    final Map<String, dynamic> menu = items[index];
    // Ambil daftar addon hanya dari endpoint user (sesuai permintaan)
    List addonOptions = (menu['addonOptions'] as List?) ?? [];
    try {
      final dynamic menuId = menu['menuId'] ?? menu['menu_id'] ?? menu['id'];
      if (menuId != null) {
        final res = await CheckoutPageService.fetchMenuDetailUser(
          menuId: int.tryParse(menuId.toString()) ?? 0,
        );
        if (res.addonOptions.isNotEmpty) {
          addonOptions = res.addonOptions;
          items[index]['addonOptions'] = res.addonOptions; // cache
        }
      }
      debugPrint(
        '[CHECKOUT] EditSheet(user) addonOptions=${addonOptions.length}',
      );
    } catch (e) {
      debugPrint('[CHECKOUT] Gagal fetch addon (user) $e');
    }
    final TextEditingController noteController = TextEditingController(
      text: menu['note'] ?? '',
    );
    // Kumpulkan addon terpilih (label) seperti di Cart dialog
    List<String> selectedAddons = [];
    if (menu['addon'] is List) {
      selectedAddons = List<String>.from(menu['addon']);
    } else if (menu['addon'] is String &&
        (menu['addon'] as String).trim().isNotEmpty) {
      selectedAddons = [menu['addon'] as String];
    }
    // Jika ada label terpilih yang belum ada di addonOptions (mungkin karena dihapus di server?), tambahkan placeholder agar tetap terlihat
    final existingLabels = addonOptions
        .map((e) => (e is Map) ? e['label']?.toString() : null)
        .whereType<String>()
        .toSet();
    for (final lab in selectedAddons) {
      if (!existingLabels.contains(lab)) {
        addonOptions.add({'id': null, 'label': lab, 'price': 0, 'image': null});
      }
    }

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
                            child:
                                (menu['image'] ?? '').toString().startsWith(
                                  'http',
                                )
                                ? Image.network(
                                    menu['image'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    ),
                                  )
                                : Image.asset(
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
                                        color: Colors.grey,
                                        size: 40,
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
                            final label = opt['label']?.toString() ?? '';
                            final priceInt = (opt['price'] is num)
                                ? (opt['price'] as num).toInt()
                                : int.tryParse(
                                        opt['price']?.toString() ?? '0',
                                      ) ??
                                      0;
                            final priceStr = priceInt > 0
                                ? '(+Rp${priceInt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')})'
                                : '';
                            return InkWell(
                              onTap: () {
                                setStateDialog(() {
                                  if (label.isEmpty) return;
                                  if (selectedAddons.contains(label)) {
                                    selectedAddons.remove(label);
                                  } else {
                                    selectedAddons.add(label);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value:
                                          label.isNotEmpty &&
                                          selectedAddons.contains(label),
                                      activeColor: const Color(0xFFD53D3D),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (_) {
                                        setStateDialog(() {
                                          if (label.isEmpty) return;
                                          if (selectedAddons.contains(label)) {
                                            selectedAddons.remove(label);
                                          } else {
                                            selectedAddons.add(label);
                                          }
                                        });
                                      },
                                    ),
                                    // Gambar addon jika ada
                                    if (((opt['image'] ?? '') as String)
                                        .toString()
                                        .isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child:
                                            (opt['image'] as String).startsWith(
                                              'http',
                                            )
                                            ? Image.network(
                                                opt['image'],
                                                width: 42,
                                                height: 42,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    Container(
                                                      width: 42,
                                                      height: 42,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        size: 20,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              )
                                            : Image.asset(
                                                opt['image'] ?? '',
                                                width: 42,
                                                height: 42,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    Container(
                                                      width: 42,
                                                      height: 42,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Icon(
                                                        Icons.image,
                                                        size: 20,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              ),
                                      )
                                    else
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.extension,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        label.isEmpty
                                            ? '(Addon tidak dikenal)'
                                            : '$label $priceStr',
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                            onPressed: () async {
                              int totalAddonPrice = 0;
                              final chosenIds = <int>[];
                              for (var opt in addonOptions) {
                                if (selectedAddons.contains(opt['label'])) {
                                  final priceVal = (opt['price'] is num)
                                      ? (opt['price'] as num).toInt()
                                      : 0;
                                  totalAddonPrice += priceVal;
                                  if (opt['id'] != null) {
                                    final idParsed = int.tryParse(
                                      opt['id'].toString(),
                                    );
                                    if (idParsed != null)
                                      chosenIds.add(idParsed);
                                  }
                                }
                              }
                              // Mapping id -> label untuk tampilan
                              final chosenIdSet = chosenIds.toSet();
                              final chosenLabels = <String>[];
                              for (final opt in addonOptions) {
                                if (opt is Map &&
                                    opt['id'] != null &&
                                    chosenIdSet.contains(
                                      int.tryParse(opt['id'].toString()) ?? -1,
                                    )) {
                                  final lbl = opt['label']?.toString() ?? '';
                                  if (lbl.isNotEmpty) chosenLabels.add(lbl);
                                }
                              }
                              // Recalculate unit & subtotal locally (optimistic UI) sebelum sinkron server
                              final currentQty = (() {
                                final q = menu['qty'] ?? items[index]['qty'];
                                if (q is num) return q.toInt();
                                final qi = int.tryParse(q?.toString() ?? '');
                                return qi ?? 1;
                              })();
                              // Cari base price (tanpa addon). Prioritas: field 'base_price' kalau ada, else harga_satuan - addonPrice lama, else price
                              int basePrice = 0;
                              if (items[index]['base_price'] is num) {
                                basePrice = (items[index]['base_price'] as num)
                                    .toInt();
                              } else if (menu['base_price'] is num) {
                                basePrice = (menu['base_price'] as num).toInt();
                              } else if (items[index]['harga_satuan'] is num &&
                                  items[index]['addonPrice'] is num) {
                                basePrice =
                                    (items[index]['harga_satuan'] as num)
                                        .toInt() -
                                    (items[index]['addonPrice'] as num).toInt();
                              } else if (menu['price'] is num) {
                                basePrice = (menu['price'] as num).toInt();
                              } else if (items[index]['price'] is num) {
                                basePrice = (items[index]['price'] as num)
                                    .toInt();
                              }
                              final newUnitPrice = basePrice + totalAddonPrice;
                              final newSubtotal = newUnitPrice * currentQty;
                              setState(() {
                                items[index]['note'] = noteController.text;
                                items[index]['addon'] =
                                    chosenLabels; // labels utk tampilan
                                items[index]['addonIds'] = List<int>.from(
                                  chosenIds,
                                );
                                items[index]['addonPrice'] = totalAddonPrice;
                                items[index]['base_price'] = basePrice;
                                items[index]['harga_satuan'] = newUnitPrice;
                                items[index]['subtotal'] = newSubtotal;
                              });
                              // Sinkron ke server (add_or_update_cart_item.php)
                              try {
                                final resp =
                                    await CheckoutPageService.syncItemQtyToServer(
                                      item: items[index],
                                      geraiId: _geraiId,
                                      note: noteController.text,
                                    );
                                final it = resp.updatedItem;
                                if (it != null && mounted) {
                                  setState(() {
                                    if (it['harga_satuan'] is num) {
                                      items[index]['harga_satuan'] =
                                          (it['harga_satuan'] as num).toInt();
                                    }
                                    if (it['subtotal'] is num) {
                                      items[index]['subtotal'] =
                                          (it['subtotal'] as num).toInt();
                                    }
                                  });
                                }
                              } catch (e) {
                                debugPrint('[CHECKOUT] edit sync error: $e');
                              }
                              _cartDirty =
                                  true; // ensure cart reloads when popping back
                              if (mounted) Navigator.of(context).pop();
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

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    return Image.asset(
      path,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(
        width: 60,
        height: 60,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat checkout: $_error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchCheckoutData,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_noSelectionMatch) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.pink),
            onPressed: () => Navigator.of(context).pop(_cartDirty),
          ),
          title: const Text(
            'Checkout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          centerTitle: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.remove_shopping_cart,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Item yang dipilih tidak ditemukan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kemungkinan item sudah dihapus / berubah. Silakan kembali ke keranjang dan pilih ulang.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD53D3D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali ke Keranjang'),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
              onPressed: () => Navigator.of(context).pop(_cartDirty),
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
              if (_missingSelectedIds.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Text(
                    'Beberapa item (${_missingSelectedIds.length}) tidak ditemukan dan tidak ikut checkout.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF8D6E00),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                                    child: _buildImage(item['image'] ?? ''),
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
                                          // Gunakan subtotal server jika ada
                                          int lineTotal;
                                          if (item['subtotal'] is num) {
                                            lineTotal =
                                                (item['subtotal'] as num)
                                                    .toInt();
                                          } else {
                                            final unit =
                                                item['harga_satuan'] is num
                                                ? (item['harga_satuan'] as num)
                                                      .toInt()
                                                : (item['price'] is num)
                                                ? (item['price'] as num).toInt()
                                                : 0;
                                            final qty = (item['qty'] is num)
                                                ? (item['qty'] as num).toInt()
                                                : 1;
                                            lineTotal =
                                                unit *
                                                qty; // unit already includes addons if any
                                          }
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
                                                          final ok =
                                                              await _confirmDeleteItem(
                                                                items[i],
                                                              );
                                                          if (ok) {
                                                            await _deleteItem(
                                                              i,
                                                              navigateBackAfter:
                                                                  true,
                                                            );
                                                          }
                                                        } else {
                                                          setState(() {
                                                            items[i]['qty']--;
                                                          });
                                                          _syncItemQtyToServer(
                                                            items[i],
                                                          );
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
                                                        _syncItemQtyToServer(
                                                          items[i],
                                                        );
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
                      onTap: () => setState(() {
                        isDelivery = true; // pengantaran boleh cash/qris
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomFilterChip(
                      label: 'Pickup',
                      selected: !isDelivery,
                      onTap: () => setState(() {
                        isDelivery = false; // pickup: hilangkan opsi cash
                        if (selectedPayment == 'cash') {
                          selectedPayment = 'qris';
                        }
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Lokasi Pengantaran / Pickup
              InkWell(
                onTap: () async {
                  if (!isDelivery) return;
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddressPage(
                        popOnPick: true,
                        selectedAddressId: selectedAddressId,
                      ),
                    ),
                  );
                  // Jika AddressPage mengembalikan ApiAddress (alamat yang dipilih), set langsung
                  if (result != null) {
                    // Hindari tipe langsung agar tidak perlu import model khusus
                    final mapCandidate = <String, dynamic>{};
                    try {
                      // Gunakan refleksi sederhana via toString fallback jika object
                      // Cek properti umum dengan operator [] jika possible
                      // Jika result sudah Map langsung pakai
                      if (result is Map) {
                        mapCandidate.addAll(
                          result.map((k, v) => MapEntry(k.toString(), v)),
                        );
                        final rid = result['id'] ?? result['address_id'];
                        if (rid != null) {
                          final parsed = int.tryParse(rid.toString());
                          if (parsed != null) selectedAddressId = parsed;
                        }
                      } else {
                        // Fallback: coba akses via getter standar
                        final dynamic r = result;
                        mapCandidate['nama_penerima'] = r.namaPenerima;
                        mapCandidate['nama_gedung'] = r.namaGedung;
                        mapCandidate['detail_pengantaran'] =
                            r.detailPengantaran;
                        mapCandidate['no_hp'] = r.noHp;
                        try {
                          final dynamic rid = r.id;
                          if (rid != null) {
                            final parsed = int.tryParse(rid.toString());
                            if (parsed != null) selectedAddressId = parsed;
                          }
                        } catch (_) {}
                      }
                    } catch (_) {}
                    if (mapCandidate.isNotEmpty) {
                      setState(() {
                        selectedAddress = {
                          'nama_penerima':
                              mapCandidate['nama_penerima'] ??
                              mapCandidate['namaPenerima'] ??
                              '',
                          'nama_gedung':
                              mapCandidate['nama_gedung'] ??
                              mapCandidate['namaGedung'] ??
                              '',
                          'detail_pengantaran':
                              mapCandidate['detail_pengantaran'] ??
                              mapCandidate['detailPengantaran'] ??
                              '',
                          'no_hp':
                              mapCandidate['no_hp'] ??
                              mapCandidate['noHp'] ??
                              '',
                        };
                      });
                    }
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
                                    (selectedAddress!['nama_gedung'] ??
                                            selectedAddress!['namaGedung'] ??
                                            '')
                                        .toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF602829),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${selectedAddress!['nama_penerima'] ?? selectedAddress!['namaPenerima']} - ${selectedAddress!['no_hp'] ?? selectedAddress!['noHp']}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (selectedAddress!['detail_pengantaran'] ??
                                            selectedAddress!['detailPengantaran'] ??
                                            '')
                                        .toString(),
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
                  // Jika pickup, paksa tetap qris (non tunai)
                  if (!isDelivery && selectedPayment != 'qris') {
                    setState(() => selectedPayment = 'qris');
                  }
                  await showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (ctx) {
                      final bool pickup = !isDelivery;
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
                              if (!pickup) // hanya tampilkan Tunai jika pengantaran
                                ListTile(
                                  leading: const Icon(
                                    Icons.money,
                                    color: Color(0xFFD53D3D),
                                    size: 32,
                                  ),
                                  title: const Text(
                                    'Tunai',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              if (pickup)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Pembayaran tunai tidak tersedia untuk pickup.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
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
                          selectedPayment == 'qris' ? 'QRIS' : 'Tunai',
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
                    if (_creatingTransaction) return; // prevent double
                    setState(() => _creatingTransaction = true);
                    try {
                      final itemsPayload = items.map((it) {
                        final addonLabels =
                            (it['addon'] as List?)
                                ?.whereType<String>()
                                .toList() ??
                            [];
                        final addonIds = <int>[];
                        final opts = (it['addonOptions'] as List?) ?? [];
                        for (final lab in addonLabels) {
                          try {
                            final match = opts.firstWhere(
                              (o) => o is Map && o['label'] == lab,
                              orElse: () => null,
                            );
                            if (match is Map && match['id'] != null) {
                              final pid = int.tryParse(match['id'].toString());
                              if (pid != null) addonIds.add(pid);
                            }
                          } catch (_) {}
                        }
                        final cartItemId =
                            it['id_keranjang_item'] ?? it['cartItemId'];
                        return {
                          'id_menu': it['menu_id'] ?? it['menuId'],
                          'jumlah': it['qty'],
                          'harga_satuan': it['harga_satuan'] ?? it['price'],
                          'subtotal':
                              it['subtotal'] ??
                              ((it['price'] ?? 0) + _addonTotalFor(it)) *
                                  (it['qty'] ?? 1),
                          'note': it['note'] ?? '',
                          'addons': addonIds,
                          if (cartItemId != null) 'cart_item_id': cartItemId,
                        };
                      }).toList();
                      final map = {
                        'id_gerai': _geraiId,
                        'total_harga': total,
                        'is_delivery': isDelivery,
                        'jenis_pengantaran': isDelivery
                            ? 'pengantaran'
                            : 'pickup',
                        'metode_pembayaran':
                            (!isDelivery && selectedPayment == 'cash')
                            ? 'qris'
                            : selectedPayment,
                        'biaya_pengantaran': isDelivery ? deliveryFee : 0,
                        'items': itemsPayload,
                      };
                      // Pastikan id_alamat ikut terkirim otomatis jika mode pengantaran
                      if (isDelivery) {
                        int? finalAddressId = selectedAddressId;
                        // Jika belum terisi, coba derive dari selectedAddress map (mungkin belum trigger listener)
                        if (finalAddressId == null && selectedAddress != null) {
                          final cand =
                              selectedAddress!['id_alamat'] ??
                              selectedAddress!['id'] ??
                              selectedAddress!['address_id'];
                          if (cand != null) {
                            final parsed = int.tryParse(cand.toString());
                            if (parsed != null) finalAddressId = parsed;
                          }
                          if (finalAddressId != null) {
                            selectedAddressId =
                                finalAddressId; // cache agar konsisten
                          }
                        }
                        if (finalAddressId != null && finalAddressId > 0) {
                          map['id_alamat'] = finalAddressId;
                        } else {
                          debugPrint(
                            '[CHECKOUT] WARNING: isDelivery tetapi id_alamat belum tersedia – tidak dikirim',
                          );
                        }
                      }
                      debugPrint(
                        '[CHECKOUT] Creating transaction payload has id_alamat=' +
                            (map['id_alamat']?.toString() ?? 'NONE'),
                      );
                      final tx = await CheckoutPageService.createTransaction(
                        payload: map,
                      );
                      String? bookingId = tx.bookingId;
                      if (mounted) {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CheckoutProcessPage(bookingId: bookingId),
                              ),
                            )
                            .then((value) {
                              // Setelah kembali dari proses, tutup halaman checkout dan kirim flag refresh ke Cart
                              if (mounted) {
                                Navigator.of(context).pop(value == true);
                              }
                            });
                      }
                    } catch (e) {
                      debugPrint('[CHECKOUT] create transaksi gagal: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal membuat transaksi.'),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _creatingTransaction = false);
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

  void _onAddressChanged() {
    if (!mounted) return;
    final a = _addressStore.selected;
    setState(() {
      selectedAddress = {
        'nama_penerima': a.namaPenerima,
        'nama_gedung': a.namaGedung,
        'detail_pengantaran': a.detailPengantaran,
        'no_hp': a.noHp,
      };
      // Simpan juga id alamat terpilih agar bisa dikirim saat create_transaction
      try {
        // Beberapa implementasi Address belum punya id; abaikan kalau tidak ada
        final dynamic aid = (a as dynamic).id;
        if (aid != null) {
          final parsed = int.tryParse(aid.toString());
          if (parsed != null) selectedAddressId = parsed;
        }
      } catch (_) {
        // ignore jika properti id tidak tersedia
      }
    });
  }

  @override
  void dispose() {
    _addressStore.removeListener(_onAddressChanged);
    super.dispose();
  }
}
