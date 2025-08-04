import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import 'periksa_menu_page.dart';

class TambahMenuPage extends StatefulWidget {
  const TambahMenuPage({super.key});

  @override
  TambahMenuPageState createState() => TambahMenuPageState();
}

class TambahMenuPageState extends State<TambahMenuPage> {
  String? _selectedCategory;
  XFile? _menuImage;

  final TextEditingController _namaMenuController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _jumlahStokController = TextEditingController();

  bool _isTersedia = false;

  final String cloudName = 'dip8i3f6x';
  final String uploadPreset = 'dpr_bites';

  Future<void> _pickMenuImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _menuImage = image;
      });
    }
  }

  Future<String?> _uploadToCloudinary(XFile? image, String publicId) async {
    if (image == null) return null;

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      return data['secure_url'];
    } else {
      return null;
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF602829)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Tambah Menu",
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Afacad',
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Nama menu", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                TextField(
                  controller: _namaMenuController,
                  decoration: const InputDecoration(
                    hintText: "Beri nama hidangan",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                const Text("Foto hidangan", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                _menuImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_menuImage!.path), height: 120, fit: BoxFit.cover),
                      )
                    : Container(
                        height: 120,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text("Belum ada gambar")),
                      ),
                const SizedBox(height: 8),
                CustomButtonKotak(text: "Pilih gambar", onPressed: _pickMenuImage),
                const SizedBox(height: 10),

                const Text("Deskripsi", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                TextField(
                  controller: _deskripsiController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: "Masukkan deskripsi hidangan ini",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                const Text("Harga", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                TextField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Masukkan harga menu",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                const Text("Kategori", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  hint: const Text("Pilih kategori menu"),
                  value: _selectedCategory,
                  items: ['Makanan', 'Minuman', 'Dessert']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                const Text("Jumlah Stok", style: TextStyle(fontSize: 16)),
                TextField(
                  controller: _jumlahStokController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Masukkan jumlah stok",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                CheckboxListTile(
                  title: const Text("Tersedia"),
                  value: _isTersedia,
                  onChanged: (val) => setState(() => _isTersedia = val ?? false),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: CustomButtonKotak(
            text: "Periksa menu",
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('userId') ?? '';
              final menuName = _namaMenuController.text.trim().replaceAll(' ', '_');

              String? imageUrl;
              if (_menuImage != null) {
                imageUrl = await _uploadToCloudinary(_menuImage, 'menus/$userId/$menuName');
              }

              final menuMap = {
                'userId': userId,
                'name': _namaMenuController.text.trim(),
                'description': _deskripsiController.text.trim(),
                'category': _selectedCategory,
                'imageUrl': imageUrl,
                'price': int.tryParse(_hargaController.text.trim()) ?? 0,
                'stock': int.tryParse(_jumlahStokController.text.trim()) ?? 0,
                'available': _isTersedia,
                'createdAt': DateTime.now(),
                'editedAt': DateTime.now(),
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PeriksaMenuPage(menuData: menuMap),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
