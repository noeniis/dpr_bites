import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import '../../../../../app/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddOnFormPage extends StatefulWidget {
  const AddOnFormPage({super.key});

  @override
  State<AddOnFormPage> createState() => _AddOnFormPageState();
}

class _AddOnFormPageState extends State<AddOnFormPage> {
  XFile? _addOnImage;
  bool _isTersedia = false;
  final String _dummyUser = 'ikafahriza';
  Future<void> _pickAddOnImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _addOnImage = image;
      });
    }
  }
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Tambah Add On', style: TextStyle(color: Color(0xFF602829), fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Color(0xFF602829)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto Add On
                const Text('Foto Add On', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
                const SizedBox(height: 6),
                _addOnImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_addOnImage!.path),
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
                  onPressed: _pickAddOnImage,
                ),
                const SizedBox(height: 12),
              const Text('Nama Add On', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
              const SizedBox(height: 6),
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama add on',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Deskripsi', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
              const SizedBox(height: 6),
              TextField(
                controller: _deskripsiController,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'Deskripsi singkat add on',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Harga', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
              const SizedBox(height: 6),
              TextField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Rp Masukkan harga',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Jumlah stok', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
              const SizedBox(height: 6),
              TextField(
                controller: _stokController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Masukkan jumlah stok',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
              CustomButtonKotak(
                text: 'Simpan Add On',
                onPressed: () {
                  if (_namaController.text.trim().isNotEmpty) {
                    Navigator.pop(context, {
                      'nama': _namaController.text.trim(),
                      'deskripsi': _deskripsiController.text.trim(),
                      'harga': _hargaController.text.trim(),
                      'stok': _stokController.text.trim(),
                      'foto': _addOnImage?.path,
                      'tersedia': _isTersedia.toString(),
                      'user': _dummyUser,
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
