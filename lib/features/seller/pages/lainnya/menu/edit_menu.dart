import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../app/gradient_background.dart';
import '../../../../../common/widgets/custom_widgets.dart';

class EditMenuPage extends StatefulWidget {
  final Map<String, dynamic> menu;
  final Function(Map<String, dynamic>)? onSave;
  final Function(String)? onDelete;
  const EditMenuPage({Key? key, required this.menu, this.onSave, this.onDelete}) : super(key: key);

  @override
  State<EditMenuPage> createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  int _stock = 1;
  late TextEditingController _stockController;
  String _category = 'Makanan';
  bool _delivery = true;
  bool _pickup = true;
  bool _available = true;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menu['name'] ?? '');
    _descController = TextEditingController(text: widget.menu['description'] ?? '');
    _priceController = TextEditingController(text: widget.menu['price']?.toString() ?? '');
    _stock = widget.menu['stock'] ?? 1;
    _stockController = TextEditingController(text: _stock.toString());
    _category = widget.menu['category'] ?? 'Makanan';
    _delivery = true;
    _pickup = true;
    _available = (widget.menu['stock'] ?? 1) > 0;
    _imageUrl = widget.menu['imageUrl'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _saveMenu() async {
    final updatedMenu = {
      ...widget.menu,
      'name': _nameController.text,
      'description': _descController.text,
      'price': int.tryParse(_priceController.text) ?? 0,
      'stock': _stock,
      'imageUrl': _imageUrl,
      'category': _category,
      'available': _available,
    };
    // Update ke Firestore
    if (widget.menu['id'] != null) {
      await FirebaseFirestore.instance.collection('menus').doc(widget.menu['id']).update(updatedMenu);
    }
    widget.onSave?.call(updatedMenu);
    if (mounted) Navigator.pop(context);
  }

  void _deleteMenu() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus menu ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true && widget.menu['id'] != null) {
      await FirebaseFirestore.instance.collection('menus').doc(widget.menu['id']).delete();
      widget.onDelete?.call(widget.menu['id']);
      if (mounted) Navigator.pop(context);
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Edit Menu', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nama menu
                  const Text('Nama menu', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Beri nama hidangan',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Foto hidangan
                  const Text('Foto hidangan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _imageUrl.isNotEmpty
                            ? Image.network(
                                _imageUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Center(child: Text('Gagal load gambar')),
                                ),
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Center(child: Text('Belum ada gambar')),
                              ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            // Upload ke Cloudinary
                            final uri = Uri.parse('https://api.cloudinary.com/v1_1/dip8i3f6x/image/upload');
                            final request = http.MultipartRequest('POST', uri)
                              ..fields['upload_preset'] = 'dpr_bites'
                              ..files.add(await http.MultipartFile.fromPath('file', picked.path));
                            final response = await request.send();
                            Navigator.of(context).pop();
                            if (response.statusCode == 200) {
                              final responseBody = await response.stream.bytesToString();
                              final data = json.decode(responseBody);
                              if (mounted) {
                                setState(() {
                                  _imageUrl = data['secure_url'] ?? '';
                                });
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Ukuran gambar maksimal 2 MB. Pastikan kualitas gambar jelas dan menggugah selera.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 12),
                  // Deskripsi
                  const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan deskripsi hidangan ini',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Harga
                  const Text('Harga', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan harga menu',
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Kategori
                  const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: <String>['Makanan', 'Minuman', 'Dessert'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value ?? 'Makanan';
                      });
                    },
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Jumlah stok
                  const Text('Jumlah stok', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        _stock = int.tryParse(val) ?? 1;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Masukkan jumlah stok',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Ketersediaan
                  const Text('Ketersediaan', style: TextStyle(fontWeight: FontWeight.bold)),
                  CheckboxListTile(
                    title: const Text('Tersedia'),
                    value: _available,
                    onChanged: (val) {
                      setState(() {
                        _available = val ?? true;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFA1A1), Color(0xFFFFA1A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: CustomButtonKotak(
                  text: 'Selesai',
                  onPressed: _saveMenu,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButtonKotak(
                  text: 'Hapus menu',
                  onPressed: _deleteMenu,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
