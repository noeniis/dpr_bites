import 'package:dpr_bites/features/seller/pages/profil_gerai/tambah_menu_page.dart';
import 'package:flutter/material.dart';
import '../../../../../app/gradient_background.dart';
import '../../../../../common/widgets/custom_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Data menu diambil dari Firestore

  Future<void> _editMenu(Map<String, dynamic> menu, String docId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMenuPage(
          menu: menu,
          onSave: (updatedMenu) async {
            await FirebaseFirestore.instance.collection('menus').doc(docId).update(updatedMenu);
          },
          onDelete: (id) async {
            await FirebaseFirestore.instance.collection('menus').doc(docId).delete();
          },
        ),
      ),
    );
    setState(() {}); // Refresh setelah kembali dari edit
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
              // Search only, full width
              SizedBox(
                width: double.infinity,
                child: CustomInputField(
                  hintText: 'Cari',
                  controller: _searchController,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  onSubmitted: (val) => setState(() => _search = val),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('menus').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Belum ada menu'));
                    }
                    List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                    List<Map<String, dynamic>> menus = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return data;
                    }).toList();
                    // Search filter only
                    if (_search.isNotEmpty) {
                      menus = menus.where((m) => m['name'].toLowerCase().contains(_search.toLowerCase())).toList();
                    }
                    return ListView.separated(
                      itemCount: menus.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final menu = menus[idx];
                        final docId = menu['id'];
                        return CustomEmptyCard(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: menu['imageUrl'] != null && menu['imageUrl'] != ''
                              ? Image.network(
                                  menu['imageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                        ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(menu['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
                                      onPressed: () => _editMenu(menu, docId),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              CustomButtonOval(
                text: 'Tambah menu',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TambahMenuPage()),
                  );
                  setState(() {}); // Refresh setelah kembali dari tambah
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
