import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import '../../../../../app/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class AddOnFormPage extends StatefulWidget {
  const AddOnFormPage({super.key});

  @override
  State<AddOnFormPage> createState() => _AddOnFormPageState();
}

class _AddOnFormPageState extends State<AddOnFormPage> {
  XFile? _addOnImage;
  bool _isTersedia = false;
  String? _idUser;
  String? _idGerai;
  @override
  void initState() {
    super.initState();
    _loadUserAndGerai();
  }

  Future<void> _loadUserAndGerai() async {
    final prefs = await SharedPreferences.getInstance();
    _idUser = prefs.getString('id_users');
    if (_idUser != null) {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/get_gerai_by_user.php'),
        body: {'id_users': _idUser},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['id_gerai'] != null) {
        setState(() {
          _idGerai = data['id_gerai'].toString();
        });
      }
    }
  }

  Future<String?> _uploadToCloudinary(String imagePath) async {
    // Ganti dengan cloudinary preset dan cloud name kamu
    const cloudName = 'dip8i3f6x';
    const uploadPreset = 'dpr_bites';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imagePath));
    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = jsonDecode(resStr);
      return resJson['secure_url'];
    }
    return null;
  }

  Future<void> _submitAddOn() async {
  if (_idGerai == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID Gerai tidak ditemukan')),
    );
    return;
  }

  try {
    // Upload gambar kalau ada
    String? imageUrl;
    if (_addOnImage != null) {
      imageUrl = await _uploadToCloudinary(_addOnImage!.path);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal upload gambar')),
        );
        return;
      }
    }

    // Validasi harga dan stok
    final harga = int.tryParse(_hargaController.text.trim()) ?? 0;
    final stok = int.tryParse(_stokController.text.trim()) ?? 0;

    if (_namaController.text.trim().isEmpty || harga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan harga wajib diisi')),
      );
      return;
    }

    // Kirim data ke API
    final response = await http.post(
      Uri.parse('http://10.0.2.2/dpr_bites_api/add_addon.php'),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: {
        'id_gerai': _idGerai!,
        'nama_addon': _namaController.text.trim(),
        'harga': harga.toString(),
        'deskripsi': _deskripsiController.text.trim(),
        'image_path': imageUrl ?? '',
        'stok': stok.toString(),
        'tersedia': _isTersedia ? '1' : '0',
      },
    );



    // Parse hasil
    final resJson = jsonDecode(response.body);

    if (resJson['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal simpan add on: ${resJson['error'] ?? 'Unknown error'}',
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

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
                    _submitAddOn();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama Add On wajib diisi')));
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
