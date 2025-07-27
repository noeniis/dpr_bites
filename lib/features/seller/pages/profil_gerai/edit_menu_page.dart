import 'dart:io'; // Import File untuk menggunakan File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';

class EditMenuPage extends StatefulWidget {
  const EditMenuPage({super.key});

  @override
  _EditMenuPageState createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  final TextEditingController _namaMenuController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _jumlahStokController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Pilihan checkbox
  bool _isPengantaran = false;
  bool _isAmbilTempat = false;
  bool _isTersedia = false;

  // Variabel untuk gambar
  XFile? _image;

  // Fungsi untuk memilih gambar
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  // Fungsi untuk menghapus menu
  void _hapusMenu() {
    // Tambahkan logika penghapusan menu di sini (misalnya dari database)
  }

  // Fungsi untuk menambah stok
  void _incrementStock() {
    setState(() {
      int currentStock = int.tryParse(_jumlahStokController.text) ?? 0;
      currentStock++;
      _jumlahStokController.text = currentStock.toString();
    });
  }

  // Fungsi untuk mengurangi stok
  void _decrementStock() {
    setState(() {
      int currentStock = int.tryParse(_jumlahStokController.text) ?? 0;
      if (currentStock > 0) {
        currentStock--;
        _jumlahStokController.text = currentStock.toString();
      }
    });
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
            icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
            onPressed: () {
              Navigator.pushNamed(context, '/semua_menu_page');
            },
          ),
          title: const Text(
            "Edit Menu",
            style: TextStyle(
              fontSize: 30,
              fontFamily: 'Afacad',
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 15)],
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Menu
                const Text(
                  "Nama menu",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaMenuController,
                  decoration: const InputDecoration(
                    hintText: "Nama menu",
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
                const SizedBox(height: 16),

                // Foto Hidangan
                const Text(
                  "Foto hidangan",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text(
                    "Pilih gambar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                _image != null
                    ? Image.file(
                        File(_image!.path),
                        width: 100,
                        height: 100,
                      ) // Menampilkan gambar yang dipilih
                    : Container(),

                const SizedBox(height: 16),

                // Deskripsi
                const Text(
                  "Deskripsi",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),

                // Kategori
                const Text(
                  "Kategori",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  hint: const Text("Pilih kategori menu"),
                  items: <String>['Makanan', 'Minuman'].map((String value) {
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
                const SizedBox(height: 16),

                // Jenis layanan
                const Text(
                  "Jenis layanan",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Colors.black,
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
                        fontSize: 22,
                        fontFamily: 'Afacad',
                        color: Colors.black,
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
                        fontSize: 22,
                        fontFamily: 'Afacad',
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Harga
                const Text(
                  "Harga",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),

                // Ketersediaan
                const Text(
                  "Ketersediaan",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Colors.black,
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
                const SizedBox(height: 16),

                // Jumlah Stok
                const Text(
                  "Jumlah stok",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Afacad',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _decrementStock, // Mengurangi stok
                    ),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _jumlahStokController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _incrementStock, // Menambah stok
                    ),
                  ],
                ),
                const Spacer(),

                // Button Selesai
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/semua_menu_page');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Selesai",
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),
                  ),
                ),

                // Button Hapus Menu
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hapusMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9E9595),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Hapus Menu",
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),
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
