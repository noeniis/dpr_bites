import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/features/user/services/menu_detail_page_service.dart';

class MenuDetailPage extends StatefulWidget {
  final Map<String, dynamic> menu;
  final int initialQty;
  // Daftar ID addon yang sudah dipilih (saat edit)
  final List<int>? initialAddonIds;
  // Catatan awal (saat edit)
  final String? initialNote;
  const MenuDetailPage({
    super.key,
    required this.menu,
    this.initialQty = 0,
    this.initialAddonIds,
    this.initialNote,
  });

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  late int qty;
  final TextEditingController noteController = TextEditingController();
  // Simpan ID addon (int)
  List<int> selectedAddons = [];
  // user handled via service
  bool _favorited = false;
  bool _favBusy = false;

  // We'll keep original passed menu as fallback, and load fresh data (including addons) from API
  Map<String, dynamic>?
  _menuData; // will contain keys: id, name, desc, price, image, addonOptions[]
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    qty = widget.initialQty > 0 ? widget.initialQty : 1;
    _menuData = Map<String, dynamic>.from(widget.menu);

    // 1. Isi selectedAddons dari parameter jika ada
    if (widget.initialAddonIds != null) {
      selectedAddons = List<int>.from(widget.initialAddonIds!);
    } else {
      // 2. Atau coba ambil dari map menu jika field-field standar tersedia
      //    Mencari key umum: selectedAddons, addonIds, addons
      final dynamic raw =
          widget.menu['selectedAddons'] ??
          widget.menu['addonIds'] ??
          widget.menu['addons'];
      if (raw is List) {
        selectedAddons = raw
            .where((e) => e != null)
            .map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList();
      }
    }

    // 3. Catatan awal
    if (widget.initialNote != null && widget.initialNote!.isNotEmpty) {
      noteController.text = widget.initialNote!;
    } else if (widget.menu['note'] is String) {
      noteController.text = widget.menu['note'];
    }

    // 4. Init user id then fetch detail & favorite status
    final id = widget.menu['id'];
    _init(id?.toString());
  }

  Future<void> _init(String? id) async {
    if (id != null) {
      await _fetchMenuDetail(id);
      await _loadFavoriteStatus(id);
    }
  }

  Future<void> _loadFavoriteStatus(String id) async {
    final st = await MenuDetailPageService.getFavoriteStatus(id);
    if (!mounted) return;
    setState(() => _favorited = st.favorited);
  }

  Future<void> _toggleFavorite() async {
    if (_favBusy) return;
    _favBusy = true;
    final id = _menuData?['id'] ?? widget.menu['id'];
    if (id == null) {
      _favBusy = false;
      return;
    }
    final prev = _favorited;
    setState(() => _favorited = !prev); // optimistic
    final res = await MenuDetailPageService.toggleFavorite(id.toString());
    if (!mounted) return;
    if (res.success) {
      setState(() => _favorited = res.favorited);
    } else {
      setState(() => _favorited = prev); // revert on failure
      final msg = res.error ?? 'Gagal update favorite';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    _favBusy = false;
  }

  Future<void> _fetchMenuDetail(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await MenuDetailPageService.fetchMenuDetail(id);
    if (!mounted) return;
    if (res.success) {
      _menuData = res.menu;
      // Filter selectedAddons agar hanya ID yang masih ada
      selectedAddons = selectedAddons
          .where(
            (aid) =>
                (_menuData!['addonOptions'] as List).any((o) => o['id'] == aid),
          )
          .toList();
      setState(() => _loading = false);
    } else {
      setState(() {
        _error = res.error ?? 'Gagal memuat';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = _menuData ?? widget.menu;
    final List addonOptions = menu['addonOptions'] is List
        ? menu['addonOptions'] as List
        : [];
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: true,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 80, top: 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child:
                                    (menu['image'] is String &&
                                        (menu['image'] as String).startsWith(
                                          'http',
                                        ))
                                    ? Image.network(
                                        menu['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.black12,
                                          child: const Icon(
                                            Icons.fastfood,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        (menu['image'] ??
                                                'assets/placeholder.png')
                                            .toString(),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (menu['name'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (menu['desc'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFFB0B0B0),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _favorited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _favorited ? Colors.red : Colors.grey,
                              size: 30,
                            ),
                            onPressed: _favBusy ? null : _toggleFavorite,
                            tooltip: _favorited
                                ? 'Hapus dari Favorit'
                                : 'Tambah ke Favorit',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Rp ${menu['price'].toString().replaceAll(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), '.')}"
                            .replaceAll('.', '.'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      // Tampilkan section Add-on hanya jika ada addon
                      if (addonOptions.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Pilih Add-on:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(addonOptions.length, (i) {
                          final opt = addonOptions[i];
                          final id = opt['id'];
                          final label = opt['label'] ?? '';
                          final price = opt['price'] ?? 0;
                          final image = opt['image'];
                          final isSelected = selectedAddons.contains(id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedAddons.add(id);
                                } else {
                                  selectedAddons.remove(id);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                if (image != null &&
                                    image.toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          (image is String &&
                                              image.startsWith('http'))
                                          ? Image.network(
                                              image,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    color: Colors.black12,
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 18,
                                                      color: Colors.black38,
                                                    ),
                                                  ),
                                            )
                                          : Image.asset(
                                              (image ??
                                                      'assets/placeholder.png')
                                                  .toString(),
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    price > 0
                                        ? '$label (+Rp${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')})'
                                        : label,
                                  ),
                                ),
                              ],
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                      ],
                      const SizedBox(height: 18),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          hintText: "Tuliskan catatan untuk restoran jika ada",
                          hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD53D3D),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD53D3D),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Color(0xFFD53D3D),
                              size: 32,
                            ),
                            onPressed: () {
                              if (qty > 1) {
                                setState(() => qty--);
                              } else {
                                // Kirim qty 0 agar menu dihapus dari selectedMenus
                                Navigator.pop(context, {
                                  'qty': 0,
                                  'addons': List<String>.from(selectedAddons),
                                  'remove': true,
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFFD53D3D),
                              size: 32,
                            ),
                            onPressed: () => setState(() => qty++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ),
            // Tombol tambah fixed di bawah
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: CustomButtonOval(
                  text: "Tambah",
                  onPressed: () {
                    Navigator.pop(context, {
                      'qty': qty,
                      'addonIds': List<int>.from(selectedAddons),
                      'addonOptions': menu['addonOptions'] ?? [],
                      'note': noteController.text,
                    });
                  },
                ),
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            if (_error != null && !_loading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 90,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final id = menu['id'];
                              if (id != null) _fetchMenuDetail(id.toString());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MenuDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> menu;
  const MenuDetailBottomSheet({super.key, required this.menu});

  @override
  State<MenuDetailBottomSheet> createState() => _MenuDetailBottomSheetState();
}

class _MenuDetailBottomSheetState extends State<MenuDetailBottomSheet> {
  int qty = 1;
  final TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    return GradientBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      menu['image'],
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        menu['name'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.pink,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(menu['desc'], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                Text(
                  "Rp ${menu['price']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    hintText: "Tuliskan catatan untuk restoran jika ada",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: qty > 1 ? () => setState(() => qty--) : null,
                    ),
                    Text(
                      '$qty',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => qty++),
                    ),
                    const Spacer(),
                    CustomButtonOval(
                      text: "Tambah",
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
