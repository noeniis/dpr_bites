import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart'; // tetap dipakai utk icon/location fallback
import 'package:dpr_bites/common/data/address_store.dart';
import 'package:dpr_bites/features/user/pages/address/address_page.dart';
import 'package:http/http.dart' as http;
import 'pembayaran_qris_dialog.dart';
import '../history/history_page.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
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
  Map<String, dynamic>?
  selectedAddress; // disamakan ke map agar mudah isi dari API
  int? selectedAddressId; // id alamat terpilih untuk sinkron ke AddressPage
  late final AddressStore _addressStore;
  bool _loading = true;
  String? _error;
  bool _noSelectionMatch =
      false; // jika ID terpilih tidak ditemukan di data API
  bool _retryAfterMismatch = false; // retry sekali bila pertama kosong
  List<int> _missingSelectedIds = []; // id yang dipilih tapi tidak muncul
  final int _userId = 1; // TODO: ambil dari auth saat tersedia
  int _geraiId = 0; // diisi dari arguments
  List<int> _selectedCartItemIds =
      []; // dari cart: id_keranjang_item yang dipilih
  bool _didFetch = false;
  bool _cartDirty = false; // tandai jika ada perubahan utk refresh cart

  Future<void> _prefetchSelectedItemsDetail(String baseUrl) async {
    if (_selectedCartItemIds.isEmpty) return; // hanya saat dari cart
    final futures = <Future>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      // Jika sudah punya addonOptions dan desc skip
      final hasAddons =
          (it['addonOptions'] is List) &&
          (it['addonOptions'] as List).isNotEmpty;
      final hasDesc =
          (it['desc']?.toString().isNotEmpty ?? false) ||
          (it['description']?.toString().isNotEmpty ?? false);
      if (hasAddons && hasDesc) continue;
      final menuId = it['menu_id'] ?? it['id_menu'] ?? it['id'];
      if (menuId == null) continue;
      final mid = int.tryParse(menuId.toString());
      if (mid == null) continue;
      futures.add(_fetchSingleMenuDetail(baseUrl, mid, i));
    }
    if (futures.isEmpty) return;
    try {
      await Future.wait(futures);
      if (mounted) setState(() {}); // refresh UI
    } catch (_) {}
  }

  Future<void> _fetchSingleMenuDetail(
    String baseUrl,
    int menuId,
    int index,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/dpr_bites_api/get_menu_detail_user.php?id=$menuId',
      );
      final resp = await http.get(uri, headers: {'Accept': 'application/json'});
      if (resp.statusCode != 200) return;
      dynamic data;
      try {
        var raw = resp.body.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
        data = jsonDecode(raw);
      } catch (_) {
        return;
      }
      if (data is Map && data['success'] == true) {
        final d = data['data'];
        if (d is Map) {
          final updated = Map<String, dynamic>.from(items[index]);
          // desc
          if (!(updated['desc']?.toString().isNotEmpty ?? false)) {
            updated['desc'] = d['description'] ?? d['desc'] ?? updated['desc'];
          }
          // addonOptions
          if (!(updated['addonOptions'] is List) ||
              (updated['addonOptions'] as List).isEmpty) {
            final opts = d['addons'] ?? d['addonOptions'];
            if (opts is List) {
              updated['addonOptions'] = opts;
            }
          }
          items[index] = updated;
        }
      }
    } catch (_) {}
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
      final baseUrl =
          'http://10.0.2.2'; // ganti dengan IP LAN jika pakai device fisik
      final uri = Uri.parse(
        '$baseUrl/dpr_bites_api/get_checkout_data.php?user_id=$_userId&gerai_id=$_geraiId',
      );
      debugPrint('[CHECKOUT] Fetching: $uri');
      final resp = await http.get(uri, headers: {'Accept': 'application/json'});
      debugPrint('[CHECKOUT] Status: ${resp.statusCode}');
      debugPrint(
        '[CHECKOUT] Raw body (first 300 chars): ${resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body}',
      );
      if (resp.statusCode == 200) {
        dynamic data;
        try {
          var raw = resp.body;
          // Bersihkan BOM & spasi tak perlu
          raw = raw.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
          data = jsonDecode(raw);
        } catch (e) {
          _error = 'Format JSON tidak valid: $e';
          if (mounted)
            setState(() {
              _loading = false;
            });
          return;
        }
        if (data is Map && data['success'] == true) {
          final d = data['data'] as Map? ?? {};
          restaurantName = (d['restaurantName'] ?? '').toString();
          deliveryFee = (d['deliveryFee'] is num)
              ? (d['deliveryFee'] as num).toInt()
              : 0;
          qrisPath = (d['qrisPath']?.toString().isNotEmpty ?? false)
              ? d['qrisPath'].toString()
              : null;
          if (d['latitude'] != null && d['longitude'] != null) {
            geraiLat = double.tryParse(d['latitude'].toString());
            geraiLng = double.tryParse(d['longitude'].toString());
          }
          final allItems = ((d['items'] as List?) ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (allItems.isNotEmpty) {
            try {
              debugPrint(
                '[CHECKOUT] allItems count=${allItems.length}; first keys=${allItems.first.keys.join(',')}',
              );
            } catch (_) {}
          } else {
            debugPrint('[CHECKOUT] allItems empty from API');
          }
          if (_selectedCartItemIds.isNotEmpty) {
            // Tambahkan variasi key id item dari API (camelCase, snake_case, dll)
            const possibleIdKeys = [
              'id_keranjang_item',
              'cart_item_id',
              'keranjang_item_id',
              'id_item',
              'cartItemId', // key yang muncul di response API sekarang
              'cartItemID',
              'cartItem_id',
            ];
            final allFoundIds = <int>{};
            for (final m in allItems) {
              for (final k in possibleIdKeys) {
                if (m[k] != null) {
                  final id = int.tryParse(m[k].toString());
                  if (id != null) allFoundIds.add(id);
                }
              }
            }
            debugPrint(
              '[CHECKOUT] API ids=$allFoundIds selected=$_selectedCartItemIds',
            );
            items = allItems.where((m) {
              for (final k in possibleIdKeys) {
                if (m[k] != null) {
                  final id = int.tryParse(m[k].toString());
                  if (id != null && _selectedCartItemIds.contains(id)) {
                    m['id_keranjang_item'] = id; // normalize
                    return true;
                  }
                }
              }
              return false;
            }).toList();
            if (items.isEmpty) {
              if (!_retryAfterMismatch) {
                _retryAfterMismatch = true;
                debugPrint('[CHECKOUT] No match, retry in 400ms');
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (mounted) _fetchCheckoutData();
                });
              } else {
                _noSelectionMatch = true;
              }
            } else {
              final foundIds = items
                  .map((e) => e['id_keranjang_item'] as int)
                  .toSet();
              _missingSelectedIds = _selectedCartItemIds
                  .where((id) => !foundIds.contains(id))
                  .toList();
              if (_missingSelectedIds.isNotEmpty) {
                debugPrint(
                  '[CHECKOUT] Partial missing ids: $_missingSelectedIds',
                );
              }
              await _prefetchSelectedItemsDetail(baseUrl);
            }
          } else {
            items = allItems; // fallback mode: no explicit selection passed
          }
          final addr = d['address'];
          if (addr is Map) {
            selectedAddress = Map<String, dynamic>.from(addr);
            // Set id alamat jika tersedia
            final dynamic rawId = addr['id'] ?? addr['address_id'];
            if (rawId != null) {
              final parsed = int.tryParse(rawId.toString());
              if (parsed != null) {
                selectedAddressId = parsed;
              }
            }
          }
        } else {
          _error = data is Map
              ? (data['message']?.toString() ?? 'Gagal memuat')
              : 'Format tidak dikenali';
        }
      } else {
        _error = 'HTTP ${resp.statusCode}';
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
      final userId = _userId;
      final geraiId = _geraiId;
      final menuId =
          item['menu_id'] ?? item['menuId'] ?? item['id_menu'] ?? item['id'];
      final qty = item['qty'];
      if (menuId == null || qty == null) return;
      // Pastikan kita tidak mengirim addons kosong yang akan menghapus addon di server.
      // Prefer gunakan field 'addonIds' (list int). Jika belum ada, turunkan dari label 'addon' menggunakan 'addonOptions'.
      List<int> derivedAddonIds = [];
      if (item['addonIds'] is List) {
        derivedAddonIds = (item['addonIds'] as List)
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
      } else {
        // Turunkan dari label => id di addonOptions
        final labels =
            (item['addon'] as List?)?.map((e) => e.toString()).toList() ??
            const [];
        if (labels.isNotEmpty) {
          final opts = (item['addonOptions'] as List?) ?? const [];
          for (final lab in labels) {
            try {
              final opt = opts.firstWhere(
                (o) => (o is Map) && (o['label']?.toString() == lab),
                orElse: () => const {},
              );
              if (opt is Map && opt['id'] != null) {
                final pid = int.tryParse(opt['id'].toString());
                if (pid != null && pid > 0) derivedAddonIds.add(pid);
              }
            } catch (_) {}
          }
          if (derivedAddonIds.isNotEmpty) {
            item['addonIds'] = derivedAddonIds; // cache
          }
        }
      }
      final payload = <String, dynamic>{
        'user_id': userId,
        'gerai_id': geraiId,
        'menu_id': int.tryParse(menuId.toString()) ?? menuId,
        'qty': qty,
      };
      // sertakan item_id agar server update baris yang tepat
      final cartItemId = item['id_keranjang_item'] ?? item['cartItemId'];
      if (cartItemId != null) {
        final cid = int.tryParse(cartItemId.toString());
        if (cid != null && cid > 0) payload['item_id'] = cid;
      }
      // Hanya kirim 'addons' jika kita punya daftar id valid (agar server tidak menghapus saat qty update)
      if (derivedAddonIds.isNotEmpty) {
        payload['addons'] = derivedAddonIds;
      }
      await http
          .post(
            Uri.parse(
              'http://10.0.2.2/dpr_bites_api/add_or_update_cart_item.php',
            ),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .then((res) {
            if (res.statusCode == 200) {
              try {
                final json = jsonDecode(res.body);
                if (json is Map && json['success'] == true) {
                  final data = json['data'];
                  if (data is Map && data['item'] is Map) {
                    final it = Map<String, dynamic>.from(data['item']);
                    // Update local item with authoritative pricing
                    item['subtotal'] = it['subtotal'];
                    item['harga_satuan'] = it['harga_satuan'];
                    _cartDirty = true; // ada perubahan
                    // Simpan kembali addon ids dari server (jika ada) agar qty berikutnya tetap konsisten
                    if (it['addons'] is List) {
                      item['addonIds'] = (it['addons'] as List)
                          .map((e) => int.tryParse(e.toString()) ?? 0)
                          .where((e) => e > 0)
                          .toList();
                    }
                  }
                }
              } catch (_) {}
            }
          });
      if (mounted) setState(() {});
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
    final payload = {
      'user_id': _userId,
      'gerai_id': _geraiId,
      'menu_id': int.tryParse(menuId.toString()) ?? menuId,
      'qty': 0,
    };
    final cartItemId = item['id_keranjang_item'] ?? item['cartItemId'];
    if (cartItemId != null) {
      final cid = int.tryParse(cartItemId.toString());
      if (cid != null && cid > 0) payload['item_id'] = cid;
    }
    _cartDirty = true;
    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/add_or_update_cart_item.php'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        try {
          final json = jsonDecode(res.body);
          if (json is Map && json['success'] == true) {
            // Remove locally
            items.removeAt(index);
            if (mounted) setState(() {});
          }
        } catch (_) {}
      }
    } catch (_) {}
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
        final uri = Uri.parse(
          'http://10.0.2.2/dpr_bites_api/get_menu_detail_user.php?id=${Uri.encodeQueryComponent(menuId.toString())}',
        );
        final resp = await http.get(
          uri,
          headers: {'Accept': 'application/json'},
        );
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          if (body is Map && body['success'] == true) {
            final data = body['data'];
            if (data is Map && data['addonOptions'] is List) {
              final listRaw = (data['addonOptions'] as List).whereType<Map>();
              final full = <Map<String, dynamic>>[];
              for (final m in listRaw) {
                final idVal = m['id'] ?? m['id_addon'];
                final labelVal = m['label'] ?? m['nama_addon'] ?? '';
                final priceVal = (m['price'] is num)
                    ? (m['price'] as num).toInt()
                    : int.tryParse(m['price']?.toString() ?? '0') ?? 0;
                full.add({
                  'id': idVal,
                  'label': labelVal,
                  'price': priceVal,
                  'image': m['image'] ?? m['image_path'] ?? '',
                });
              }
              if (full.isNotEmpty) {
                addonOptions = full;
                items[index]['addonOptions'] = full; // cache
              }
            }
          }
        }
        debugPrint(
          '[CHECKOUT] EditSheet(user) menuId=$menuId addonOptions=${addonOptions.length}',
        );
      }
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
                              setState(() {
                                items[index]['note'] = noteController.text;
                                items[index]['addon'] = selectedAddons;
                                items[index]['addonPrice'] = totalAddonPrice;
                              });
                              // Sinkron ke server (add_or_update_cart_item.php)
                              try {
                                final currentQty =
                                    menu['qty'] ?? items[index]['qty'] ?? 1;
                                final menuId =
                                    menu['menuId'] ??
                                    menu['menu_id'] ??
                                    menu['id'] ??
                                    items[index]['menuId'];
                                final cartItemId =
                                    menu['id_keranjang_item'] ??
                                    menu['cartItemId'] ??
                                    items[index]['id_keranjang_item'];
                                final prevAddons = (menu['addon'] is List)
                                    ? List<String>.from(menu['addon'])
                                    : <String>[];
                                final prevOptions =
                                    (menu['addonOptions'] as List?) ??
                                    addonOptions;
                                // Turunkan prev addon IDs
                                final prevIds = <int>{};
                                for (final opt in prevOptions) {
                                  if (opt is Map &&
                                      prevAddons.contains(opt['label'])) {
                                    final pid = int.tryParse(
                                      opt['id']?.toString() ?? '',
                                    );
                                    if (pid != null) prevIds.add(pid);
                                  }
                                }
                                final newIds = chosenIds.toSet();
                                final addonsChanged =
                                    newIds.length != prevIds.length ||
                                    !newIds.containsAll(prevIds);
                                final mapPayload = <String, dynamic>{
                                  'user_id': _userId,
                                  'gerai_id': _geraiId,
                                  'menu_id': menuId,
                                  'qty': currentQty,
                                  'note': noteController.text,
                                };
                                if (cartItemId != null) {
                                  final cid = int.tryParse(
                                    cartItemId.toString(),
                                  );
                                  if (cid != null && cid > 0)
                                    mapPayload['item_id'] = cid;
                                }
                                if (addonsChanged) {
                                  mapPayload['addons'] =
                                      chosenIds; // kirim hanya jika berubah
                                }
                                final payload = jsonEncode(mapPayload);
                                await http.post(
                                  Uri.parse(
                                    'http://10.0.2.2/dpr_bites_api/add_or_update_cart_item.php',
                                  ),
                                  headers: {
                                    'Accept': 'application/json',
                                    'Content-Type': 'application/json',
                                  },
                                  body: payload,
                                );
                                _cartDirty =
                                    true; // ensure cart reloads when popping back
                              } catch (e) {
                                debugPrint('[CHECKOUT] sync edit failed: $e');
                              }
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
                              qrisImageUrl: qrisPath,
                              onKonfirmasi: (bukti) async {
                                Navigator.of(ctx).pop();
                                // Kirim transaksi ke server
                                try {
                                  final itemsPayload = items.map((it) {
                                    final addonLabels =
                                        (it['addon'] as List?)
                                            ?.whereType<String>()
                                            .toList() ??
                                        [];
                                    final addonIds = <int>[];
                                    final opts =
                                        (it['addonOptions'] as List?) ?? [];
                                    for (final lab in addonLabels) {
                                      try {
                                        final match = opts.firstWhere(
                                          (o) => o is Map && o['label'] == lab,
                                          orElse: () => null,
                                        );
                                        if (match is Map &&
                                            match['id'] != null) {
                                          final pid = int.tryParse(
                                            match['id'].toString(),
                                          );
                                          if (pid != null) addonIds.add(pid);
                                        }
                                      } catch (_) {}
                                    }
                                    final cartItemId =
                                        it['id_keranjang_item'] ??
                                        it['cartItemId'];
                                    return {
                                      'id_menu': it['menu_id'] ?? it['menuId'],
                                      'jumlah': it['qty'],
                                      'harga_satuan':
                                          it['harga_satuan'] ?? it['price'],
                                      'subtotal':
                                          it['subtotal'] ??
                                          ((it['price'] ?? 0) +
                                                  _addonTotalFor(it)) *
                                              (it['qty'] ?? 1),
                                      'note': it['note'] ?? '',
                                      'addons': addonIds,
                                      if (cartItemId != null)
                                        'cart_item_id': cartItemId,
                                    };
                                  }).toList();
                                  final map = {
                                    'id_users': _userId,
                                    'id_gerai': _geraiId,
                                    'total_harga': total,
                                    // kirim flag boolean juga sbg fallback server
                                    'is_delivery': isDelivery,
                                    'jenis_pengantaran': isDelivery
                                        ? 'pengantaran'
                                        : 'pickup',
                                    'metode_pembayaran': 'qris',
                                    'biaya_pengantaran': isDelivery
                                        ? deliveryFee
                                        : 0,
                                    'items': itemsPayload,
                                  };
                                  debugPrint(
                                    '[CHECKOUT][POST][QRIS] payload=' +
                                        map.toString(),
                                  );
                                  // convert bukti to base64
                                  try {
                                    final bytes = await bukti.readAsBytes();
                                    final b64 = base64Encode(bytes);
                                    map['bukti_base64'] =
                                        'data:image/${bukti.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg'};base64,' +
                                        b64;
                                  } catch (_) {}
                                  await http.post(
                                    Uri.parse(
                                      'http://10.0.2.2/dpr_bites_api/create_transaction.php',
                                    ),
                                    headers: const {
                                      'Accept': 'application/json',
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode(map),
                                  );
                                } catch (e) {
                                  debugPrint('[CHECKOUT] transaksi gagal: $e');
                                }
                                if (mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const HomePage(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              onBatal: () {
                                // hanya tutup dialog tanpa redirect
                              },
                            ),
                          );
                        },
                      );
                    } else {
                      // Pembayaran tunai: langsung kirim transaksi tanpa popup tambahan
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
                                final pid = int.tryParse(
                                  match['id'].toString(),
                                );
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
                          'id_users': _userId,
                          'id_gerai': _geraiId,
                          'total_harga': total,
                          'is_delivery': isDelivery, // fallback di backend
                          'jenis_pengantaran': isDelivery
                              ? 'pengantaran'
                              : 'pickup',
                          'metode_pembayaran': 'cash',
                          'biaya_pengantaran': isDelivery ? deliveryFee : 0,
                          'items': itemsPayload,
                        };
                        debugPrint(
                          '[CHECKOUT][POST][CASH] payload=' + map.toString(),
                        );
                        final resp = await http.post(
                          Uri.parse(
                            'http://10.0.2.2/dpr_bites_api/create_transaction.php',
                          ),
                          headers: const {
                            'Accept': 'application/json',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode(map),
                        );
                        debugPrint(
                          '[CHECKOUT][POST][CASH] status=${resp.statusCode} body=${resp.body}',
                        );
                        bool success = false;
                        if (resp.statusCode == 200) {
                          try {
                            final body = jsonDecode(resp.body);
                            if (body is Map && body['success'] == true)
                              success = true;
                          } catch (_) {}
                        }
                        if (mounted) {
                          if (success) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomePage(),
                              ),
                              (r) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Gagal membuat transaksi tunai. Lihat log untuk detail.',
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('[CHECKOUT] transaksi tunai gagal: $e');
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
    });
  }

  @override
  void dispose() {
    _addressStore.removeListener(_onAddressChanged);
    super.dispose();
  }
}
