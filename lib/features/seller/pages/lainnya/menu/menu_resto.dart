
import 'package:flutter/material.dart';
import 'package:dpr_bites/features/seller/pages/profil_gerai/tambah_menu_page.dart';
import '../../../../../app/gradient_background.dart';
import '../../../../../common/widgets/custom_widgets.dart';
import 'package:dpr_bites/features/seller/services/menu_service.dart';
import 'package:dpr_bites/features/seller/models/menu_model.dart';
import 'package:dpr_bites/features/seller/models/addon_model.dart';
import 'package:dpr_bites/features/seller/services/addon_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/menu/edit_addon_page.dart';
import 'edit_menu.dart';
import 'package:dpr_bites/features/seller/pages/beranda/dashboard_page.dart';

class MenuRestoPage extends StatefulWidget {
  const MenuRestoPage({Key? key}) : super(key: key);

  @override
  State<MenuRestoPage> createState() => _MenuRestoPageState();
}

class _MenuRestoPageState extends State<MenuRestoPage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  int _selectedFilter = 0;
  final List<String> _filters = ['Semua', 'Menu Utama', 'Add On', 'Tersedia'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuModel> _menus = [];
  List<AddonModel> _addons = [];
  String? _idUsers;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoadingAddons = true;
  bool _isLoading = true;

  List<dynamic> get _filteredItems {
    List<MenuModel> validMenus = _menus.where((m) =>
      m.namaMenu.trim().isNotEmpty &&
      m.harga > 0 &&
      m.jumlahStok >= 0
    ).toList();
    List<dynamic> items = [...validMenus, ..._addons];
    // Search
    if (_search.isNotEmpty) {
      items = items.where((item) {
        if (item is MenuModel) {
          return item.namaMenu.toLowerCase().contains(_search.toLowerCase());
        } else if (item is AddonModel) {
          return item.namaAddon.toLowerCase().contains(_search.toLowerCase());
        }
        return false;
      }).toList();
    }
    // Filter
    if (_selectedFilter == 1) {
      items = items.where((item) => item is MenuModel).toList();
    } else if (_selectedFilter == 2) {
      items = items.where((item) => item is AddonModel).toList();
    } else if (_selectedFilter == 3) {
      items = items.where((item) {
        if (item is MenuModel) return item.tersedia;
        if (item is AddonModel) return item.tersedia;
        return false;
      }).toList();
    }
    return items;
  }

  Future<void> _fetchMenus({String filter = 'all'}) async {
    setState(() { _isLoading = true; });
    if (_idUsers == null) {
      _idUsers = await _secureStorage.read(key: 'id_users');
    }
    if (_idUsers == null) {
      setState(() { _menus = []; _isLoading = false; });
      return;
    }
    final menus = await MenuService.fetchMenusByUser(idUsers: _idUsers!, filter: filter);
    setState(() {
      _menus = menus;
      _isLoading = false;
    });
  }
  @override
  void initState() {
    super.initState();
    _fetchMenus();
    _fetchAddons();
  }

  Future<void> _fetchAddons() async {
    setState(() { _isLoadingAddons = true; });
    final addons = await AddonService.fetchAddonsByGeraiFromPrefs();
    print('[DEBUG MenuResto] hasil fetch add-on: ${addons.map((a) => a.namaAddon).toList()}');
    setState(() {
      _addons = addons;
      _isLoadingAddons = false;
    });
  }

  void _editMenu(MenuModel menu) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMenuPage(menu: menu),
      ),
    );
    if (result == true) _fetchMenus();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.red),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SellerDashboardPage()),
              );
            },
          ),
          title: const Text('Daftar Menu', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Filter (scrollable)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: CustomInputField(
                        hintText: 'Cari',
                        controller: _searchController,
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        onSubmitted: (val) => setState(() => _search = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(_filters.length, (i) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: CustomFilterChipKotak(
                        label: _filters[i],
                        selected: _selectedFilter == i,
                        onTap: () {
                          setState(() => _selectedFilter = i);
                          String filter = 'all';
                          if (i == 1) {
                            filter = 'utama';
                          } else if (i == 2) {
                            filter = 'addon';
                          } else if (i == 3) {
                            filter = 'tersedia';
                          }
                          _fetchMenus(filter: filter);
                        },
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isLoading || _isLoadingAddons
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredItems.isEmpty
                              ? const Center(child: Text('Tidak ada menu atau add-on'))
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, idx) {
                                    final item = _filteredItems[idx];
                                    if (item is MenuModel) {
                                      final nama = item.namaMenu;
                                      final harga = item.harga;
                                      final stok = item.jumlahStok;
                                      final gambar = item.gambarMenu.isNotEmpty ? item.gambarMenu : 'lib/assets/images/chalkboard_menu.jpeg';
                                      final addons = item.addons != null && item.addons!.isNotEmpty
                                          ? 'Add-ons: ' + item.addons!.map((a) => a.namaAddon).join(', ')
                                          : '';
                                      final isCheckboxEnabled = stok > 0;
                                      if (!isCheckboxEnabled && item.tersedia) {
                                        item.tersedia = false;
                                      }
                                      return CustomEmptyCard(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  gambar,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Image.asset('lib/assets/images/chalkboard_menu.jpeg', width: 60, height: 60, fit: BoxFit.cover),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                                    const SizedBox(height: 2),
                                                    Text('Rp. ${harga.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}', style: const TextStyle(fontSize: 14)),
                                                    const SizedBox(height: 2),
                                                    Text('Stok: $stok', style: TextStyle(color: Colors.red[400], fontSize: 13)),
                                                    // Hilangkan etalase
                                                    if (addons.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(addons, style: const TextStyle(fontSize: 13, color: Colors.deepPurple)),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                                                    onPressed: () => _editMenu(item),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Checkbox(
                                                    value: item.tersedia,
                                                    onChanged: isCheckboxEnabled
                                                        ? (val) async {
                                                            setState(() {
                                                              item.tersedia = val == true;
                                                            });
                                                            await MenuService.updateTersediaMenu(
                                                              idMenu: item.idMenu,
                                                              tersedia: val == true ? 1 : 0,
                                                            );
                                                          }
                                                        : null,
                                                    activeColor: Colors.green,
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else if (item is AddonModel) {
                                      final gambar = item.imagePath.isNotEmpty ? item.imagePath : 'lib/assets/images/chalkboard_menu.jpeg';
                                      final isCheckboxEnabled = item.stok > 0;
                                      if (!isCheckboxEnabled && item.tersedia) {
                                        item.tersedia = false;
                                      }
                                      return CustomEmptyCard(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: gambar.startsWith('http')
                                                    ? Image.network(
                                                        gambar,
                                                        width: 60,
                                                        height: 60,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (c, e, s) => Image.asset('lib/assets/images/chalkboard_menu.jpeg', width: 60, height: 60, fit: BoxFit.cover),
                                                      )
                                                    : Image.asset('lib/assets/images/chalkboard_menu.jpeg', width: 60, height: 60, fit: BoxFit.cover),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(item.namaAddon, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                                    const SizedBox(height: 2),
                                                    Text('Rp. ${item.harga.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}', style: const TextStyle(fontSize: 14)),
                                                    const SizedBox(height: 2),
                                                    Text('Stok: ${item.stok}', style: TextStyle(color: Colors.red[400], fontSize: 13)),
                                                    const SizedBox(height: 2),
                                                    Text('Tipe: Add-On', style: TextStyle(color: Colors.deepPurple, fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                                                    onPressed: () async {
                                                      final result = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => EditAddonPage(addon: item.toJson()),
                                                        ),
                                                      );
                                                      if (result == true) {
                                                        _fetchAddons();
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Checkbox(
                                                    value: item.tersedia,
                                                    onChanged: isCheckboxEnabled
                                                        ? (val) async {
                                                            setState(() {
                                                              item.tersedia = val == true;
                                                            });
                                                            await AddonService.updateAddonWithImage(
                                                              idAddon: item.idAddon,
                                                              namaAddon: item.namaAddon,
                                                              deskripsi: item.deskripsi,
                                                              harga: item.harga,
                                                              imagePath: item.imagePath,
                                                              tersedia: val == true,
                                                            );
                                                          }
                                                        : null,
                                                    activeColor: Colors.green,
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else {
                                      return const SizedBox();
                                    }
                                  },
                                ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CustomButtonOval(
                text: 'Tambah menu',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TambahMenuPage()),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _menus.add(MenuModel.fromJson(result));
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
