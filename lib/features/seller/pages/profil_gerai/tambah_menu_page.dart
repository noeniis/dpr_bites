import 'package:dpr_bites/features/seller/pages/profil_gerai/periksa_menu_page.dart';
import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'periksa_menu_page.dart';

class TambahMenuPage extends StatefulWidget {
  const TambahMenuPage({super.key});

  @override
  TambahMenuPageState createState() => TambahMenuPageState();
}

class TambahMenuPageState extends State<TambahMenuPage> {
  XFile? _menuImage;

  Future<void> _pickMenuImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _menuImage = image;
      });
    }
  }
  final TextEditingController _namaMenuController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _jumlahStokController =
      TextEditingController(); // Controller untuk jumlah stok

  // Pilihan checkbox
  bool _isPengantaran = false;
  bool _isAmbilTempat = false;
  bool _isTersedia = false;

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
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_menuImage!.path),
                          height: 120,
                          fit: BoxFit.cover,
                        ),
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

                // Jenis Layanan
                const Text(
                  "Jenis layanan",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Color(0xFF333333),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _isPengantaran,
                      onChanged: (bool? value) {
                        setState(() {
                          _isPengantaran = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      "Pengantaran",
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Checkbox(
                      value: _isAmbilTempat,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAmbilTempat = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      "Ambil di tempat",
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                  ],
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: CustomButtonKotak(
                    text: "Periksa menu",
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PeriksaMenuPage()),);
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
