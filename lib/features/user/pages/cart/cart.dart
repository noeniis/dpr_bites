import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpr_bites/common/data/dummy_carts.dart';
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
  void showEditMenuDialog(int restIdx, int menuIdx) async {
    final menus = carts[restIdx]['menus'] as List? ?? [];
    final menu = menus[menuIdx];
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
      builder: (context) {
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
                          ...addonOptions.map<Widget>(
                            (opt) => CheckboxListTile(
                              value: selectedAddons.contains(opt['label']),
                              title: Text(
                                '${opt['label']} ${opt['price'] > 0 ? '(+Rp${(opt['price'] as int).toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')})' : ''}',
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
                            ),
                          ),
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
                              borderSide: BorderSide(
                                color: Color(0xFFD53D3D), // merah DPR
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Color(0xFFD53D3D),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
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
                                menu['note'] = noteController.text;
                                menu['addon'] = selectedAddons;
                                menu['addonPrice'] = totalAddonPrice;
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

  List<Map<String, dynamic>> carts = freshDummyCarts();
  Map<int, Set<int>> selectedMenus = {};
  bool get isCartCompletelyEmpty {
    for (final c in carts) {
      final menus = c['menus'] as List? ?? [];
      if (menus.isNotEmpty) return false;
    }
    return true;
  }

  bool get hasAnyMenu =>
      carts.any((c) => (c['menus'] as List?)?.isNotEmpty == true);
  bool get isAllSelected {
    for (var i = 0; i < carts.length; i++) {
      final menus = carts[i]['menus'] as List? ?? [];
      if (menus.isEmpty) continue;
      if (selectedMenus[i]?.length != menus.length) return false;
    }
    return carts.isNotEmpty && selectedMenus.isNotEmpty;
  }

  int get totalPrice {
    int total = 0;
    selectedMenus.forEach((restIdx, menuIdxs) {
      final menus = carts[restIdx]['menus'] as List? ?? [];
      for (var idx in menuIdxs) {
        final menu = menus[idx];
        int price = (menu['price'] is int)
            ? menu['price'] as int
            : (menu['price'] as num).toInt();
        int addonPrice = (menu['addonPrice'] is int)
            ? menu['addonPrice'] as int
            : (menu['addonPrice'] ?? 0 as num).toInt();
        int qty = (menu['qty'] is int)
            ? menu['qty'] as int
            : (menu['qty'] as num).toInt();
        total += (price + addonPrice) * qty;
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
      final menus = carts[restIdx]['menus'] as List? ?? [];
      if (selectedMenus[restIdx]?.length == menus.length) {
        selectedMenus.remove(restIdx);
      } else {
        selectedMenus[restIdx] = Set<int>.from(
          List.generate(menus.length, (i) => i),
        );
      }
    });
  }

  void toggleAllSelect(bool? value) {
    setState(() {
      if (isAllSelected) {
        selectedMenus.clear();
      } else {
        for (var i = 0; i < carts.length; i++) {
          final menus = carts[i]['menus'] as List? ?? [];
          if (menus.isNotEmpty) {
            selectedMenus[i] = Set<int>.from(
              List.generate(menus.length, (j) => j),
            );
          }
        }
      }
    });
  }

  void changeQty(int restIdx, int menuIdx, int delta) async {
    final menus = carts[restIdx]['menus'] as List? ?? [];
    final menu = menus[menuIdx];
    int qty = menu['qty'] ?? 1;
    qty += delta;
    if (qty < 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Yakin untuk menghapus menu ini pada keranjang?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Iya'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        setState(() {
          menus.removeAt(menuIdx);
          // Remove selection for this menu
          selectedMenus[restIdx]?.remove(menuIdx);
          // If no menus left, remove the entire restaurant card
          if (menus.isEmpty) {
            carts.removeAt(restIdx);
            // Rebuild selectedMenus with shifted restaurant indices
            final newSelected = <int, Set<int>>{};
            selectedMenus.forEach((rIdx, mSet) {
              if (rIdx == restIdx) return;
              final newR = rIdx > restIdx ? rIdx - 1 : rIdx;
              newSelected[newR] = mSet;
            });
            selectedMenus = newSelected;
          } else {
            // Adjust menu indices for selections in this restaurant
            if (selectedMenus[restIdx] != null) {
              final updated = <int>{};
              for (var idx in selectedMenus[restIdx]!) {
                if (idx < menuIdx) {
                  updated.add(idx);
                } else if (idx > menuIdx) {
                  updated.add(idx - 1);
                }
              }
              if (updated.isEmpty) {
                selectedMenus.remove(restIdx);
              } else {
                selectedMenus[restIdx] = updated;
              }
            }
          }
        });
      }
      // Jika tidak, tidak melakukan apa-apa
    } else {
      setState(() {
        menu['qty'] = qty;
      });
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
          titleSpacing: 0,
          systemOverlayStyle:
              Theme.of(context).appBarTheme.systemOverlayStyle?.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ) ??
              const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(color: Colors.transparent),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
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
            if (isAllSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      // Remove all restaurant cards
                      carts.clear();
                      selectedMenus.clear();
                    });
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
            if (hasAnyMenu)
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
                    final menus = cart['menus'] is List
                        ? cart['menus'] as List
                        : <dynamic>[];
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
                                int addonPrice = menu['addonPrice'] ?? 0;
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
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          menu['image'] ??
                                              'lib/assets/images/pecel.jpeg',
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 48,
                                                    height: 48,
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                        ),
                                      ),
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
                                            if (menu['addon'] != null &&
                                                (menu['addon'] as List)
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
                                                      final List<
                                                        Map<String, Object>
                                                      >
                                                      addonOptions =
                                                          (menu['addonOptions']
                                                                  as List?)
                                                              ?.cast<
                                                                Map<
                                                                  String,
                                                                  Object
                                                                >
                                                              >() ??
                                                          [];
                                                      final opt = addonOptions
                                                          .firstWhere(
                                                            (o) =>
                                                                o['label'] ==
                                                                label,
                                                            orElse: () =>
                                                                <
                                                                  String,
                                                                  Object
                                                                >{},
                                                          );
                                                      final price =
                                                          opt.isNotEmpty
                                                          ? opt['price'] as int
                                                          : 0;
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: i == 0
                                                                  ? 2.0
                                                                  : 0.0,
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
                                                'Catatan: '
                                                '${(menu['note'] != null && (menu['note'] as String?)?.isNotEmpty == true) ? menu['note'] : '-'}',
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
                                                    'Rp${((menu['price'] + addonPrice) * menu['qty']).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
            if (!hasAnyMenu)
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
            // Tambahkan outline abu-abu tipis dan drop shadow
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
                    'Rp${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CheckoutPage()),
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

// ...existing code...
