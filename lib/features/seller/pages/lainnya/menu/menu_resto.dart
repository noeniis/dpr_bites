
import 'package:dpr_bites/features/seller/pages/profil_gerai/tambah_menu_page.dart';
import 'package:flutter/material.dart';
import '../../../../../app/gradient_background.dart';
import '../../../../../common/widgets/custom_widgets.dart';
import '../../../../../common/data/dummy_menus.dart';
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

  List<Map<String, dynamic>> _menus = [
    ...List<Map<String, dynamic>>.from(dummyMenus),
    {
      'id': 'addon-1',
      'name': 'Telur Ceplok',
      'desc': 'Add on telur ceplok',
      'price': 4000,
      'stock': 50,
      'image': 'lib/assets/images/pecel.jpeg',
      'isAddOn': true,
      'tersedia': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredMenus {
    List<Map<String, dynamic>> menus = List<Map<String, dynamic>>.from(_menus);
    if (_search.isNotEmpty) {
      menus = menus.where((m) => m['name'].toLowerCase().contains(_search.toLowerCase())).toList();
    }
    if (_selectedFilter == 1) {
      // Menu Utama
      menus = menus.where((m) => m['isAddOn'] != true).toList();
    } else if (_selectedFilter == 2) {
      // Add On
      menus = menus.where((m) => m['isAddOn'] == true).toList();
    } else if (_selectedFilter == 3) {
      // Tersedia
      menus = menus.where((m) => (m['tersedia'] == true || (m['stock'] ?? 0) > 0)).toList();
    }
    return menus;
  }

  void _editMenu(Map<String, dynamic> menu) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMenuPage(
          menu: menu,
          onSave: (updatedMenu) {
            setState(() {
              final idx = _menus.indexWhere((m) => m['id'] == updatedMenu['id']);
              if (idx != -1) _menus[idx] = updatedMenu;
            });
          },
          onDelete: (id) {
            setState(() {
              _menus.removeWhere((m) => m['id'] == id);
            });
          },
        ),
      ),
    );
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
                        onTap: () => setState(() => _selectedFilter = i),
                        // icon: i == 0 ? const Icon(Icons.cake_outlined, size: 18) : null,
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredMenus.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final menu = _filteredMenus[idx];
                    return CustomEmptyCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                menu['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(menu['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                  const SizedBox(height: 2),
                                  Text('Rp. ${menu['price'].toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('Stok: ${menu['stock']}', style: TextStyle(color: Colors.red[400], fontSize: 13)),
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
                                  value: menu['tersedia'] == true,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        menu['tersedia'] = true;
                                        if (menu['stock'] != null && menu['stock'] is int && menu['stock'] <= 0) {
                                          menu['stock'] = 1;
                                        }
                                      } else {
                                        menu['tersedia'] = false;
                                        // Optional: set stock to 0 if unchecked
                                        // menu['stock'] = 0;
                                      }
                                    });
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
