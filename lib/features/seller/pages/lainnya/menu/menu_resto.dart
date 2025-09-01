import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/seller/pages/profil_gerai/tambah_menu_page.dart';
import 'package:flutter/material.dart';
import '../../../../../app/gradient_background.dart';
import '../../../../../common/widgets/custom_widgets.dart';
import 'package:dpr_bites/features/seller/services/menu_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_menu.dart';
import 'edit_addon_page.dart';
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

  List<Map<String, dynamic>> _menus = [];
  String? _idUsers;
  int? _idGerai;
  bool _isLoading = true;

  List<Map<String, dynamic>> get _filteredMenus {
    List<Map<String, dynamic>> menus = List<Map<String, dynamic>>.from(_menus);
    // Otomatis set tersedia = false jika stok habis
    for (final m in menus) {
      if ((m['id_menu'] != null && (m['jumlah_stok'] == 0 || m['jumlah_stok'] == '0')) ||
          (m['id_addon'] != null && (m['stok'] == 0 || m['stok'] == '0'))) {
        if (m['tersedia'] != 0 && m['tersedia'] != false) {
          m['tersedia'] = 0;
          // Update ke database juga
          if (m['id_menu'] != null) {
            MenuService.updateTersediaMenu(idMenu: m['id_menu'], tersedia: 0);
          } else if (m['id_addon'] != null) {
            MenuService.updateTersediaMenu(idAddon: m['id_addon'], tersedia: 0);
          }
        }
      }
    }
    if (_search.isNotEmpty) {
      menus = menus.where((m) => (m['nama_menu'] ?? m['nama_addon'] ?? '').toLowerCase().contains(_search.toLowerCase())).toList();
    }
    // Filter berdasarkan pilihan
    if (_selectedFilter == 1) {
      // Menu Utama
      menus = menus.where((m) => m['id_menu'] != null).toList();
    } else if (_selectedFilter == 2) {
      // Add On
      menus = menus.where((m) => m['id_addon'] != null).toList();
    } else if (_selectedFilter == 3) {
      // Tersedia
      menus = menus.where((m) => (m['tersedia'] == 1 || m['tersedia'] == true)).toList();
    }
    return menus;
  }

  Future<void> _fetchMenus({String filter = 'all'}) async {
    setState(() { _isLoading = true; });
    if (_idUsers == null) {
      final prefs = await SharedPreferences.getInstance();
      _idUsers = prefs.getString('id_users');
      print('DEBUG id_users (menu_resto): $_idUsers');
    }
    if (_idUsers == null) {
      print('DEBUG id_users masih null, tidak bisa fetch menu');
      setState(() { _menus = []; _isLoading = false; });
      return;
    }
    // Ambil id_gerai dari backend
    final responseGerai = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      body: {'id_users': _idUsers},
    );
    if (responseGerai.statusCode == 200) {
      final dataGerai = jsonDecode(responseGerai.body);
      print('DEBUG response get_gerai_by_user: $dataGerai');
      if (dataGerai['success'] == true && dataGerai['id_gerai'] != null) {
        _idGerai = int.tryParse(dataGerai['id_gerai'].toString());
        print('DEBUG id_gerai (menu_resto): $_idGerai');
      } else {
        print('DEBUG gagal dapat id_gerai');
        setState(() { _menus = []; _isLoading = false; });
        return;
      }
    } else {
      print('DEBUG gagal request id_gerai');
      setState(() { _menus = []; _isLoading = false; });
      return;
    }
    // Fetch menu dan add-on berdasarkan id_gerai
  final menus = await MenuService.fetchMenusByGerai(idGerai: _idGerai!, filter: filter);
    setState(() {
      _menus = menus;
      _isLoading = false;
    });
  }
  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  void _editMenu(Map<String, dynamic> menu) async {
    if (menu['id_addon'] != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditAddonPage(addon: menu),
        ),
      );
      if (result == true) _fetchMenus();
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditMenuPage(menu: menu),
        ),
      );
      if (result == true) _fetchMenus();
    }
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredMenus.isEmpty
                        ? const Center(child: Text('Tidak ada menu'))
                        : ListView.separated(
                            itemCount: _filteredMenus.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final menu = _filteredMenus[idx];
                              // final isAddOn = menu['is_addon'] == 1;
                              final nama = menu['nama_menu'] ?? menu['nama_addon'] ?? '-';
                              final harga = menu['harga'] ?? menu['harga_addon'] ?? 0;
                              final stok = menu['jumlah_stok'] ?? menu['stok'] ?? '-';
                              final gambar = menu['gambar_menu'] ?? menu['image_path'] ?? 'lib/assets/images/chalkboard_menu.jpeg';
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
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                                            onPressed: () => _editMenu(menu),
                                          ),
                                          const SizedBox(height: 4),
                                          Checkbox(
                                            value: (menu['tersedia'] == true || menu['tersedia'] == 1),
                                            onChanged: (val) async {
                                              setState(() {
                                                menu['tersedia'] = val == true;
                                              });
                                              // Update ke database jika menu utama
                                              if (menu['id_menu'] != null) {
                                                await MenuService.updateTersediaMenu(
                                                  idMenu: menu['id_menu'],
                                                  tersedia: val == true ? 1 : 0,
                                                );
                                              } else if (menu['id_addon'] != null) {
                                                await MenuService.updateTersediaMenu(
                                                  idAddon: menu['id_addon'],
                                                  tersedia: val == true ? 1 : 0,
                                                );
                                              }
                                            },
                                            activeColor: Colors.green,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
                      _menus.add(result);
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
