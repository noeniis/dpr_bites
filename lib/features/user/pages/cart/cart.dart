import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../common/widgets/custom_widgets.dart';
import '../checkout/checkout_page.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final int _userId = 1; // TODO: replace with real user id
  List<Map<String, dynamic>> carts = [];
  Map<int, Set<int>> selectedMenus = {};
  bool _loading = false; // minimal spinner to keep UI feel
  bool _busy = false;
  bool _dirty = false; // track if any change made to inform previous page

  static const String _baseApi = 'http://10.0.2.2/dpr_bites_api';

  Widget _buildMenuImage(String? path, {double size = 48, double radius = 8}) {
    if (path == null || path.isEmpty) {
      return _placeholder(size, radius);
    }
    String url = path;
    // If path does not start with http, treat as relative (file name or subfolder)
    if (!url.startsWith('http')) {
      // Heuristics: if path already has 'uploads' assume relative folder
      if (url.contains('/') || url.contains('uploads')) {
        url = '$_baseApi/$url';
      } else {
        // plain filename -> assume uploads directory
        url = '$_baseApi/uploads/$url';
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size, radius),
      ),
    );
  }

  Widget _buildDialogImage(String? path) {
    if (path == null || path.isEmpty) {
      return _dialogPlaceholder();
    }
    String url = path;
    if (!url.startsWith('http')) {
      if (url.contains('/') || url.contains('uploads')) {
        url = '$_baseApi/$url';
      } else {
        url = '$_baseApi/uploads/$url';
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _dialogPlaceholder(),
      ),
    );
  }

  Widget _placeholder(double size, double radius) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    ),
  );

  Widget _dialogPlaceholder() => Container(
    width: 100,
    height: 100,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image, size: 40, color: Colors.grey),
  );

  Widget _buildAddonImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.extension, size: 20, color: Colors.grey),
      );
    }
    String url = path;
    if (!url.startsWith('http')) {
      if (url.contains('/') || url.contains('uploads')) {
        url = '$_baseApi/$url';
      } else {
        url = '$_baseApi/uploads/$url';
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() {
      _loading = true;
    });
    try {
      final res = await http.get(
        Uri.parse(
          'http://10.0.2.2/dpr_bites_api/get_user_cart.php?user_id=$_userId',
        ),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final data = body['data'];
          if (data is List) {
            final fetched = <Map<String, dynamic>>[];
            for (final r in data) {
              if (r is Map) {
                final menus = (r['menus'] as List? ?? [])
                    .whereType<Map>()
                    .map(
                      (m) => {
                        'id_keranjang_item': m['id_keranjang_item'],
                        'menu_id': m['menu_id'],
                        'name': m['name'],
                        'desc': m['desc'],
                        'image': m['image'],
                        'price': m['price'],
                        'qty': m['qty'],
                        'addon': m['addon'] ?? <String>[],
                        'addonPrice': m['addonPrice'] ?? 0,
                        'addonOptions': m['addonOptions'] ?? [],
                        'note': m['note'] ?? '',
                      },
                    )
                    .toList();
                fetched.add({
                  'id_keranjang': r['id_keranjang'],
                  'id_gerai': r['id_gerai'],
                  'restaurantName': r['restaurantName'],
                  'estimate': r['estimate'] ?? '15-20 menit',
                  'menus': menus,
                });
              }
            }
            setState(() {
              carts = fetched;
            });
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Future<void> _syncItem({
    required int geraiId,
    required int menuId,
    required int qty,
    required List addonLabels,
    required List addonOptions,
    bool addonsExplicit = false, // send even if empty when true
    String? note,
    bool noteProvided = false,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      final addonIds = <int>[];
      for (final label in addonLabels) {
        final match = addonOptions.firstWhere(
          (o) => o is Map && o['label'] == label,
          orElse: () => null,
        );
        if (match is Map && match['id'] != null) {
          final idVal = int.tryParse(match['id'].toString());
          if (idVal != null) addonIds.add(idVal);
        }
      }
      final mapPayload = <String, dynamic>{
        'user_id': _userId,
        'gerai_id': geraiId,
        'menu_id': menuId,
        'qty': qty,
      };
      if (addonsExplicit || addonIds.isNotEmpty) {
        mapPayload['addons'] = addonIds; // explicit even if empty
      }
      if (noteProvided) {
        mapPayload['note'] = note ?? '';
      }
      final payload = jsonEncode(mapPayload);
      await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/add_or_update_cart_item.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: payload,
      );
      _dirty = true; // mark changes
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  void showEditMenuDialog(int restIdx, int menuIdx) async {
    final menus = carts[restIdx]['menus'] as List? ?? [];
    if (menuIdx < 0 || menuIdx >= menus.length) return;
    final menu = menus[menuIdx];
    final TextEditingController noteController = TextEditingController(
      text: menu['note'] ?? '',
    );
    List<String> selectedAddons = [];
    if (menu['addon'] is List)
      selectedAddons = List<String>.from(menu['addon']);
    final List addonOptions = menu['addonOptions'] ?? [];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) => Container(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.95),
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
            builder: (context, setStateDialog) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: _buildDialogImage(menu['image'] as String?)),
                  const SizedBox(height: 14),
                  Text(
                    menu['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if ((menu['desc'] ?? '').toString().isNotEmpty)
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
                      final bool checked = selectedAddons.contains(
                        opt['label'],
                      );
                      final int priceVal = opt['price'] as int? ?? 0;
                      final String priceStr = priceVal > 0
                          ? '(+Rp${priceVal.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')})'
                          : '';
                      return InkWell(
                        onTap: () {
                          setStateDialog(() {
                            if (checked) {
                              selectedAddons.remove(opt['label']);
                            } else {
                              selectedAddons.add(opt['label']);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: checked,
                                activeColor: const Color(0xFFD53D3D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (_) {
                                  setStateDialog(() {
                                    if (checked) {
                                      selectedAddons.remove(opt['label']);
                                    } else {
                                      selectedAddons.add(opt['label']);
                                    }
                                  });
                                },
                              ),
                              _buildAddonImage(opt['image'] as String?),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${opt['label']} $priceStr',
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
                        for (final opt in addonOptions) {
                          if (selectedAddons.contains(opt['label']))
                            totalAddonPrice += (opt['price'] as int);
                        }
                        setState(() {
                          menu['note'] = noteController.text;
                          menu['addon'] = selectedAddons;
                          menu['addonPrice'] = totalAddonPrice;
                        });
                        _syncItem(
                          geraiId: carts[restIdx]['id_gerai'] as int,
                          menuId: menu['menu_id'] as int,
                          qty: menu['qty'] as int,
                          addonLabels: selectedAddons,
                          addonOptions: addonOptions,
                          addonsExplicit: true,
                          note: noteController.text,
                          noteProvided: true,
                        );
                        Navigator.pop(context);
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

  bool get hasAnyMenu => carts.any((c) => (c['menus'] as List).isNotEmpty);
  bool get isAllSelected {
    for (var i = 0; i < carts.length; i++) {
      final menus = carts[i]['menus'] as List;
      if (menus.isEmpty) continue;
      if (selectedMenus[i]?.length != menus.length) return false;
    }
    return carts.isNotEmpty && selectedMenus.isNotEmpty;
  }

  bool get hasSelection => selectedMenus.isNotEmpty;

  Future<void> _deleteSelected() async {
    if (selectedMenus.isEmpty) return;
    // Copy selection to avoid modification during iteration
    final selectionCopy = Map<int, Set<int>>.fromEntries(
      selectedMenus.entries.map((e) => MapEntry(e.key, Set<int>.from(e.value))),
    );
    // For each restaurant group
    for (final restEntry in selectionCopy.entries.toList().reversed) {
      final restIdx = restEntry.key;
      if (restIdx < 0 || restIdx >= carts.length) continue;
      final menus = carts[restIdx]['menus'] as List;
      final indices = restEntry.value.toList()..sort();
      // Delete each selected menu (reverse order to keep indexes valid)
      for (final menuIdx in indices.reversed) {
        if (menuIdx < 0 || menuIdx >= menus.length) continue;
        final menu = menus[menuIdx];
        try {
          await _syncItem(
            geraiId: carts[restIdx]['id_gerai'] as int,
            menuId: menu['menu_id'] as int,
            qty: 0,
            addonLabels: (menu['addon'] as List? ?? []),
            addonOptions: (menu['addonOptions'] as List? ?? []),
            addonsExplicit: true,
            note: menu['note'] as String?,
            noteProvided: (menu['note'] as String?) != null,
          );
        } catch (_) {}
        menus.removeAt(menuIdx);
      }
      if (menus.isEmpty) {
        carts.removeAt(restIdx);
        // Need to shift indices in selection after this restIdx
        final newSel = <int, Set<int>>{};
        selectedMenus.forEach((k, v) {
          if (k == restIdx) return;
          newSel[k > restIdx ? k - 1 : k] = v;
        });
        selectedMenus = newSel;
      } else {
        selectedMenus.remove(restIdx);
      }
    }
    setState(() {
      // Clean up, mark dirty
      _dirty = true;
    });
  }

  int get totalPrice {
    int total = 0;
    selectedMenus.forEach((r, setIdx) {
      final menus = carts[r]['menus'] as List;
      for (final idx in setIdx) {
        if (idx < 0 || idx >= menus.length) continue;
        final m = menus[idx];
        total +=
            ((m['price'] as int) + (m['addonPrice'] as int)) *
            (m['qty'] as int);
      }
    });
    return total;
  }

  void toggleMenuSelect(int restIdx, int menuIdx) {
    setState(() {
      selectedMenus.putIfAbsent(restIdx, () => <int>{});
      if (selectedMenus[restIdx]!.contains(menuIdx)) {
        selectedMenus[restIdx]!.remove(menuIdx);
        if (selectedMenus[restIdx]!.isEmpty) selectedMenus.remove(restIdx);
      } else {
        selectedMenus[restIdx]!.add(menuIdx);
      }
    });
  }

  void toggleRestaurantSelect(int restIdx) {
    setState(() {
      final menus = carts[restIdx]['menus'] as List;
      if (selectedMenus[restIdx]?.length == menus.length) {
        selectedMenus.remove(restIdx);
      } else {
        selectedMenus[restIdx] = Set<int>.from(
          List.generate(menus.length, (i) => i),
        );
      }
    });
  }

  void toggleAllSelect(bool? v) {
    setState(() {
      if (isAllSelected) {
        selectedMenus.clear();
      } else {
        for (var i = 0; i < carts.length; i++) {
          final menus = carts[i]['menus'] as List;
          if (menus.isNotEmpty)
            selectedMenus[i] = Set<int>.from(
              List.generate(menus.length, (j) => j),
            );
        }
      }
    });
  }

  Future<void> changeQty(int restIdx, int menuIdx, int delta) async {
    final menus = carts[restIdx]['menus'] as List;
    if (menuIdx < 0 || menuIdx >= menus.length) return;
    final menu = menus[menuIdx];
    int qty = menu['qty'] as int? ?? 1;
    qty += delta;
    if (qty < 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Yakin untuk menghapus menu ini pada keranjang?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Iya'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _syncItem(
          geraiId: carts[restIdx]['id_gerai'] as int,
          menuId: menu['menu_id'] as int,
          qty: 0,
          addonLabels: (menu['addon'] as List),
          addonOptions: menu['addonOptions'] as List,
          addonsExplicit: true,
          note: menu['note'] as String?,
          noteProvided: (menu['note'] as String?) != null,
        );
        if (!mounted) return;
        setState(() {
          menus.removeAt(menuIdx);
          selectedMenus[restIdx]?.remove(menuIdx);
          if (menus.isEmpty) {
            carts.removeAt(restIdx);
            final newSel = <int, Set<int>>{};
            selectedMenus.forEach((k, v) {
              if (k == restIdx) return;
              newSel[k > restIdx ? k - 1 : k] = v;
            });
            selectedMenus = newSel;
          } else if (selectedMenus[restIdx] != null) {
            final updated = <int>{};
            for (final idx in selectedMenus[restIdx]!) {
              if (idx < menuIdx)
                updated.add(idx);
              else if (idx > menuIdx)
                updated.add(idx - 1);
            }
            if (updated.isEmpty) {
              selectedMenus.remove(restIdx);
            } else {
              selectedMenus[restIdx] = updated;
            }
          }
        });
      }
    } else {
      setState(() {
        menu['qty'] = qty;
      });
      _syncItem(
        geraiId: carts[restIdx]['id_gerai'] as int,
        menuId: menu['menu_id'] as int,
        qty: qty,
        addonLabels: (menu['addon'] as List),
        addonOptions: menu['addonOptions'] as List,
        // do not send addons explicitly here if empty to retain existing
        note: menu['note'] as String?,
        noteProvided: false, // quantity change shouldn't overwrite note
      );
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
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(_dirty),
            splashRadius: 22,
            tooltip: 'Kembali',
          ),
          title: const Text(
            'Keranjang',
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (hasSelection)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Hapus Item'),
                        content: const Text(
                          'Hapus item yang dipilih dari keranjang?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteSelected();
                    }
                  },
                  child: const Text(
                    'Hapus',
                    style: TextStyle(
                      color: Color(0xFFD53D3D),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (hasAnyMenu)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: carts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, restIdx) {
                    final cart = carts[restIdx];
                    final menus = cart['menus'] as List;
                    final allMenusSelected =
                        selectedMenus[restIdx]?.length == menus.length &&
                        menus.isNotEmpty;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: allMenusSelected,
                                  onChanged: (_) =>
                                      toggleRestaurantSelect(restIdx),
                                  activeColor: const Color(0xFFD53D3D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    cart['restaurantName'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Color(0xFF602829),
                                    ),
                                  ),
                                ),
                                Text(
                                  'Estimasi ${cart['estimate']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Column(
                              children: List.generate(menus.length, (menuIdx) {
                                final menu = menus[menuIdx];
                                final isSelected =
                                    selectedMenus[restIdx]?.contains(menuIdx) ??
                                    false;
                                final addonPrice =
                                    menu['addonPrice'] as int? ?? 0;
                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: menuIdx == menus.length - 1
                                        ? 0
                                        : 10,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFF3F3)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFD53D3D)
                                          : Colors.grey.shade200,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            toggleMenuSelect(restIdx, menuIdx),
                                        activeColor: const Color(0xFFD53D3D),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      _buildMenuImage(menu['image'] as String?),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    menu['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Color(0xFF602829),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () =>
                                                      showEditMenuDialog(
                                                        restIdx,
                                                        menuIdx,
                                                      ),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6.0,
                                                        ),
                                                    child: Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFFD53D3D,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if ((menu['addon'] as List)
                                                .isNotEmpty)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ...List.generate(
                                                    (menu['addon'] as List)
                                                        .length,
                                                    (i) {
                                                      final label =
                                                          (menu['addon']
                                                              as List)[i];
                                                      final addonOptions =
                                                          (menu['addonOptions']
                                                                  as List)
                                                              .whereType<Map>()
                                                              .toList();
                                                      final opt = addonOptions
                                                          .firstWhere(
                                                            (o) =>
                                                                o['label'] ==
                                                                label,
                                                            orElse: () => {},
                                                          );
                                                      final price =
                                                          opt.isNotEmpty
                                                          ? (opt['price']
                                                                as int)
                                                          : 0;
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: i == 0
                                                                  ? 2
                                                                  : 0,
                                                            ),
                                                        child: Text(
                                                          '+ $label${price > 0 ? ' (+Rp${price.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')})' : ''}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2.0,
                                              ),
                                              child: Text(
                                                'Catatan: ' +
                                                    (((menu['note'] ?? '')
                                                                as String)
                                                            .isNotEmpty
                                                        ? menu['note']
                                                        : '-'),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'Rp${(((menu['price'] as int) + addonPrice) * (menu['qty'] as int)).toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Color(0xFFD53D3D),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.remove,
                                                            size: 18,
                                                          ),
                                                          onPressed: () =>
                                                              changeQty(
                                                                restIdx,
                                                                menuIdx,
                                                                -1,
                                                              ),
                                                        ),
                                                        Text(
                                                          '${menu['qty']}',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.add,
                                                            size: 18,
                                                          ),
                                                          onPressed: () =>
                                                              changeQty(
                                                                restIdx,
                                                                menuIdx,
                                                                1,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (!_loading && !hasAnyMenu)
              const Expanded(
                child: Center(
                  child: Text(
                    'Keranjang kosong',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isAllSelected,
                  onChanged: toggleAllSelect,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: const Color(0xFFD53D3D),
                ),
                const Text(
                  'Pilih Semua',
                  style: TextStyle(fontSize: 15, color: Color(0xFF602829)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    'Rp${totalPrice.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFD53D3D),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: CustomButtonKotak(
                    text: 'Pesan',
                    onPressed: selectedMenus.isEmpty || totalPrice == 0
                        ? null
                        : () {
                            // Pastikan hanya satu gerai yang dipilih
                            final selectedRestIdx = selectedMenus.keys.toList();
                            if (selectedRestIdx.length != 1) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Tidak Bisa Checkout'),
                                  content: const Text(
                                    'Silakan pilih menu dari hanya satu gerai untuk melakukan checkout.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            final restIdx = selectedRestIdx.first;
                            final geraiId = carts[restIdx]['id_gerai'];
                            final menuIdxSet =
                                selectedMenus[restIdx] ?? <int>{};
                            // Ambil id_keranjang_item untuk difilter di checkout
                            final menus =
                                carts[restIdx]['menus'] as List? ?? [];
                            final selectedCartItemIds = <int>[];
                            for (final mi in menuIdxSet) {
                              if (mi >= 0 && mi < menus.length) {
                                final m = menus[mi];
                                final raw = m['id_keranjang_item'];
                                final parsed = int.tryParse(raw.toString());
                                if (parsed != null)
                                  selectedCartItemIds.add(parsed);
                              }
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CheckoutPage(),
                                settings: RouteSettings(
                                  arguments: {
                                    'geraiId': geraiId?.toString() ?? '',
                                    'selectedCartItemIds': selectedCartItemIds,
                                  },
                                ),
                              ),
                            );
                          },
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
