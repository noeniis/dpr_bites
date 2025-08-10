import 'package:flutter/material.dart';
import '../../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'pilih_etalase_page.dart';
import 'add_on_list_page.dart';

class EditMenuPage extends StatefulWidget {
  final Map<String, dynamic> menu;
  final Function(Map<String, dynamic>)? onSave;
  final Function(String)? onDelete;
  const EditMenuPage({Key? key, required this.menu, this.onSave, this.onDelete}) : super(key: key);

  @override
  State<EditMenuPage> createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  late TextEditingController _namaMenuController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _jumlahStokController;
  List<Map<String, String>> _selectedAddOns = [];
  List<String> _etalaseList = ['Nasi Goreng', 'Soto', 'Bakso', 'Minuman'];
  List<String> _selectedEtalase = [];
  XFile? _menuImage;
  bool _isTersedia = false;

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    _namaMenuController = TextEditingController(text: menu['name']?.toString() ?? '');
    _deskripsiController = TextEditingController(text: menu['desc']?.toString() ?? '');
    _hargaController = TextEditingController(text: menu['price']?.toString() ?? '');
    _jumlahStokController = TextEditingController(text: menu['stock']?.toString() ?? '');
    try {
      _selectedAddOns = menu['addOns'] != null ? List<Map<String, String>>.from(menu['addOns']) : [];
    } catch (_) {
      _selectedAddOns = [];
    }
    try {
      _selectedEtalase = menu['etalase'] != null ? List<String>.from(menu['etalase']) : [];
    } catch (_) {
      _selectedEtalase = [];
    }
    _isTersedia = menu['tersedia'] == true;
    if (menu['image'] != null && menu['image'].toString().isNotEmpty) {
      _menuImage = XFile(menu['image']);
    }
  }

  @override
  void dispose() {
    _namaMenuController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _jumlahStokController.dispose();
    super.dispose();
  }

  Future<void> _pickMenuImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _menuImage = image;
      });
    }
  }

  void _saveMenu() {
    final updatedMenu = {
      ...widget.menu,
      'name': _namaMenuController.text,
      'desc': _deskripsiController.text,
      'price': int.tryParse(_hargaController.text) ?? 0,
      'stock': int.tryParse(_jumlahStokController.text) ?? 0,
      'image': _menuImage?.path ?? '',
      'addOns': _selectedAddOns,
      'etalase': _selectedEtalase,
      'tersedia': _isTersedia,
    };
    widget.onSave?.call(updatedMenu);
    Navigator.pop(context);
  }

  void _deleteMenu() {
    widget.onDelete?.call(widget.menu['id']?.toString() ?? '');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF602829)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Edit Menu",
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Afacad',
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Menu
                const Text(
                  "Nama menu",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _namaMenuController,
                  decoration: const InputDecoration(
                    hintText: "Beri nama hidangan",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Foto Hidangan
                const Text(
                  "Foto hidangan",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                _menuImage != null
                    ? FutureBuilder<bool>(
                        future: File(_menuImage!.path).exists(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.data == true) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_menuImage!.path),
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'lib/assets/images/pecel_lele.jpeg',
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                        },
                      )
                    : Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text("Belum ada gambar")),
                      ),
                const SizedBox(height: 8),
                CustomButtonKotak(
                  text: "Pilih gambar",
                  onPressed: _pickMenuImage,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Ukuran gambar maksimal 2 MB. Pastikan kualitas gambar jelas dan menggugah selera.",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                // Deskripsi
                const Text(
                  "Deskripsi",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _deskripsiController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: "Masukkan deskripsi hidangan ini",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Kategori
                const Text(
                  "Kategori",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: widget.menu['kategori'] ?? 'Makanan',
                  hint: const Text("Pilih kategori menu"),
                  items: <String>['Makanan', 'Minuman', 'Dessert'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {},
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Etalase/Kategori Lain
                const Text(
                  "Kategori/Etalase Lain",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _selectedEtalase.isEmpty
                      ? [const Text('Belum ada etalase dipilih', style: TextStyle(color: Colors.black54))]
                      : _selectedEtalase.map((e) => Chip(label: Text(e))).toList(),
                ),
                const SizedBox(height: 8),
                CustomButtonKotak(
                  text: "Tambah/Pilih Etalase",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PilihEtalasePage(
                          etalaseList: _etalaseList,
                          selectedEtalase: _selectedEtalase,
                        ),
                      ),
                    );
                    if (result != null && result is List<String>) {
                      setState(() {
                        _selectedEtalase = result;
                        for (final e in result) {
                          if (!_etalaseList.contains(e)) _etalaseList.add(e);
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Harga
                const Text(
                  "Harga",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Rp Masukkan harga",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Jumlah Stok
                const Text(
                  "Jumlah stok",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _jumlahStokController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Masukkan jumlah stok",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Add On Menu Section
                const Text(
                  "Add On Menu",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _selectedAddOns.isEmpty
                      ? [const Text('Belum ada add on', style: TextStyle(color: Colors.black54))]
                      : _selectedAddOns.map((e) => Chip(label: Text(e['nama'] ?? '-'))).toList(),
                ),
                const SizedBox(height: 8),
                CustomButtonKotak(
                  text: "Tambah/Pilih Add On",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddOnListPage(selectedAddOns: _selectedAddOns),
                      ),
                    );
                    if (result != null && result is List<Map<String, String>>) {
                      setState(() {
                        _selectedAddOns = result;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Ketersediaan
                const Text(
                  "Ketersediaan",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                CheckboxListTile(
                  title: const Text("Tersedia"),
                  value: _isTersedia,
                  onChanged: (bool? value) {
                    setState(() {
                      _isTersedia = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CustomButtonKotak(
                        text: 'Simpan Perubahan',
                        onPressed: _saveMenu,
                        
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButtonKotak(
                        text: 'Hapus Menu',
                        onPressed: _deleteMenu,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
