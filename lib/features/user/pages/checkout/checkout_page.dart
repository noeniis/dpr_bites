import 'dart:convert';
import 'package:dpr_bites/features/user/pages/checkout/checkout_process_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart'; // tetap dipakai utk icon/location fallback
import 'package:dpr_bites/common/data/address_store.dart';
import 'package:dpr_bites/features/user/pages/address/address_page.dart';
import 'package:http/http.dart' as http;
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
  final int _userId = 1; // TODO: ambil dari auth saat tersedia
  int _geraiId = 0; // diisi dari arguments
  List<int> _selectedCartItemIds =
      []; // dari cart: id_keranjang_item yang dipilih
  bool _didFetch = false;

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
        '$baseUrl/dpr_bites_api/get_menu_detail.php?menu_id=$menuId',
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
          items = ((d['items'] as List?) ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          // Jika ada filter selectedCartItemIds, terapkan
          if (_selectedCartItemIds.isNotEmpty) {
            items = items.where((m) {
              final raw = m['id_keranjang_item'] ?? m['cart_item_id'];
              if (raw == null) return false;
              final id = int.tryParse(raw.toString());
              return id != null && _selectedCartItemIds.contains(id);
            }).toList();
            // Jika filter menghasilkan kosong (mungkin mismatch field), fallback ke semua
            if (items.isEmpty) {
              items = ((d['items'] as List?) ?? [])
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
            // Prefetch detail agar sama dengan dari restaurant detail
            await _prefetchSelectedItemsDetail(baseUrl);
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
    // Pastikan kita punya daftar semua addon (bukan hanya yang terpilih)
    List addonOptions = (menu['addonOptions'] as List?) ?? [];
    try {
      final dynamic menuId = menu['menuId'] ?? menu['menu_id'] ?? menu['id'];
      if (menuId != null) {
        final uri = Uri.parse(
          'http://10.0.2.2/dpr_bites_api/get_menu_detail.php?id=${Uri.encodeQueryComponent(menuId.toString())}',
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
              final fullOpts = (data['addonOptions'] as List)
                  .whereType<Map>()
                  .map(
                    (m) => {
                      'id': m['id'] ?? m['id_addon'] ?? m['addon_id'],
                      'label': m['label'] ?? m['nama_addon'] ?? m['name'],
                      'price': (m['price'] is num)
                          ? (m['price'] as num).toInt()
                          : int.tryParse(m['price']?.toString() ?? '0') ?? 0,
                      'image': m['image'] ?? m['image_path'] ?? m['path'],
                    },
                  )
                  .toList();
              // Jika server mengembalikan lebih banyak opsi daripada yang ada sekarang, pakai itu
              if (fullOpts.isNotEmpty) {
                addonOptions = fullOpts;
                items[index]['addonOptions'] = fullOpts; // cache
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[CHECKOUT] Gagal fetch addon lengkap: $e');
    }
    final TextEditingController noteController = TextEditingController(
      text: menu['note'] ?? '',
    );
    List<String> selectedAddons = [];
    if (menu['addon'] is String && (menu['addon'] as String).isNotEmpty) {
      selectedAddons = [menu['addon'] as String];
    } else if (menu['addon'] is List) {
      selectedAddons = List<String>.from(menu['addon'] as List);
    }
    // addonOptions sudah diisi / diupdate di atas

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
                            final label = opt['label'];
                            final priceInt = (opt['price'] is num)
                                ? (opt['price'] as num).toInt()
                                : 0;
                            final priceStr = priceInt > 0
                                ? '(+Rp${priceInt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')})'
                                : '';
                            return InkWell(
                              onTap: () {
                                setStateDialog(() {
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
                                      value: selectedAddons.contains(label),
                                      activeColor: const Color(0xFFD53D3D),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (_) {
                                        setStateDialog(() {
                                          if (selectedAddons.contains(label)) {
                                            selectedAddons.remove(label);
                                          } else {
                                            selectedAddons.add(label);
                                          }
                                        });
                                      },
                                    ),
                                    // Gambar addon jika ada
                                    if ((opt['image'] ?? '')
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
                                        '$label $priceStr',
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
                                final payload = jsonEncode({
                                  'user_id': _userId,
                                  'gerai_id': _geraiId,
                                  'menu_id':
                                      menu['menuId'] ??
                                      menu['menu_id'] ??
                                      menu['id'] ??
                                      items[index]['menuId'],
                                  'qty':
                                      menu['qty'] ?? items[index]['qty'] ?? 1,
                                  'addons': chosenIds,
                                  'note': noteController.text,
                                });
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
                                      if (geraiLat != null && geraiLng != null)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF4CAF50,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final url = Uri.parse(
                                              'https://www.google.com/maps/search/?api=1&query=$geraiLat,$geraiLng',
                                            );
                                            try {
                                              await launchUrl(
                                                url,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } catch (e) {
                                              debugPrint(
                                                '[CHECKOUT] gagal buka maps: $e',
                                              );
                                            }
                                          },
                                          child: const Text('Buka Maps'),
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
