import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import '../../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Future<String?> _uploadToCloudinary(String imagePath) async {
    const cloudName = 'dip8i3f6x';
    const uploadPreset = 'dpr_bites';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
  ..fields['upload_preset'] = 'dpr_bites'
      ..files.add(await http.MultipartFile.fromPath('file', imagePath));
    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = jsonDecode(resStr);
      return resJson['secure_url'];
    }
    return null;
  }
  final List<String> _kategoriList = ['makanan', 'minuman', 'jajanan'];
  String? _selectedKategori;
  late TextEditingController _namaMenuController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _jumlahStokController;
  List<Map<String, dynamic>> _etalaseMaster = [];
  // List<Map<String, dynamic>> _addOnMaster = [];
  List<Map<String, dynamic>> _selectedEtalase = [];
  List<Map<String, dynamic>> _selectedAddOns = [];
  XFile? _menuImage;
  String? _menuImageUrl;
  bool _isTersedia = false;

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    _namaMenuController = TextEditingController(text: (menu['nama_menu'] ?? menu['name'])?.toString() ?? '');
    _deskripsiController = TextEditingController(text: (menu['deskripsi_menu'] ?? menu['desc'])?.toString() ?? '');
    _hargaController = TextEditingController(text: (menu['harga'] ?? menu['price'])?.toString() ?? '');
    _jumlahStokController = TextEditingController(text: (menu['jumlah_stok'] ?? menu['stock'])?.toString() ?? '');

    // Robust parsing etalase (hanya satu, simpan sebagai list berisi satu map)
    if (menu['etalase'] is Map) {
      _selectedEtalase = [Map<String, dynamic>.from(menu['etalase'])];
    } else if (menu['etalase'] is List) {
      _selectedEtalase = (menu['etalase'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _selectedEtalase = [];
    }

    // Robust parsing add_ons (selalu list)
    if (menu['add_ons'] is List) {
      _selectedAddOns = (menu['add_ons'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _selectedAddOns = [];
    }

    // Checkbox tersedia robust
    final tersediaVal = menu['tersedia'];
    _isTersedia = tersediaVal == true || tersediaVal == 1 || tersediaVal == '1';

    if (menu['gambar_menu'] != null && menu['gambar_menu'].toString().isNotEmpty) {
      _menuImageUrl = menu['gambar_menu'];
    }
    final kategoriDb = (menu['kategori'] ?? '').toString().toLowerCase();
    _selectedKategori = _kategoriList.contains(kategoriDb) ? kategoriDb : _kategoriList.first;
    _fetchEtalaseAndAddOn();
  }

  Future<void> _fetchEtalaseAndAddOn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUser = prefs.getString('id_users');
      if (idUser != null) {
        final responseGerai = await http.post(
          Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
          body: {'id_users': idUser},
        );
        final dataGerai = jsonDecode(responseGerai.body);
        if (dataGerai['success'] == true && dataGerai['id_gerai'] != null) {
          final idGerai = dataGerai['id_gerai'].toString();
          // Etalase
          final responseEtalase = await http.get(
            Uri.parse('${getBaseUrl()}/get_etalase.php?id_gerai=$idGerai'),
          );
          final dataEtalase = jsonDecode(responseEtalase.body);
          if (dataEtalase['success'] == true && dataEtalase['etalase'] != null) {
            setState(() {
              _etalaseMaster = List<Map<String, dynamic>>.from(dataEtalase['etalase']);
            });
          }
          // Add On
          final responseAddOn = await http.get(
            Uri.parse('${getBaseUrl()}/get_addon.php?id_gerai=$idGerai'),
          );
          final dataAddOn = jsonDecode(responseAddOn.body);
          if (dataAddOn['success'] == true && dataAddOn['addons'] != null) {
            setState(() {
              // _addOnMaster = List<Map<String, dynamic>>.from(dataAddOn['addons']);
            });
          }
        }
      }
    } catch (e) {
      // ignore error, fallback dummy
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

  Future<void> _saveMenu() async {
    final idMenu = widget.menu['id_menu'] ?? widget.menu['id'] ?? '';
    String gambarMenu = _menuImageUrl ?? '';

    if (_menuImage != null) {
      final url = await _uploadToCloudinary(_menuImage!.path);
      if (url != null) {
        gambarMenu = url;
      }
    }

    final bodyData = {
      'id_menu': idMenu.toString(),
      'nama_menu': _namaMenuController.text,
      'deskripsi_menu': _deskripsiController.text,
      'harga': _hargaController.text,
      'jumlah_stok': _jumlahStokController.text,
      'gambar_menu': gambarMenu,
      'kategori': _selectedKategori ?? '',
      'etalase': _selectedEtalase.map((e) => e['id_etalase']).join(','),
      'addon': _selectedAddOns.map((a) => a['id_addon']).join(','),
      'tersedia': _isTersedia ? '1' : '0',
    };

    print("DATA DIKIRIM: $bodyData"); // Debugging

    final response = await http.post(
      Uri.parse('${getBaseUrl()}/update_menu.php'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      widget.onSave?.call({...widget.menu, ...bodyData});
      Navigator.pop(context, true); // pop dengan result true agar parent bisa reload
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal update menu!')),
      );
    }
  }


  Future<void> _deleteMenu() async {
  final idMenu = widget.menu['id_menu'] ?? widget.menu['id'] ?? '';
  final response = await http.post(
    Uri.parse('${getBaseUrl()}/delete_menu.php'),
    body: {'id_menu': idMenu.toString()},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      Navigator.pop(context, true); // trigger refresh di list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message']?.toString() ?? 'Gagal hapus menu!')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gagal hapus menu (HTTP error)!')),
    );
  }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                            : (_menuImageUrl != null && _menuImageUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _menuImageUrl!,
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
                          value: _selectedKategori,
                          hint: const Text("Pilih kategori menu"),
                          items: _kategoriList.map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value[0].toUpperCase() + value.substring(1)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedKategori = val),
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
                              : _selectedEtalase.map((e) => Chip(label: Text(e['nama_etalase'] ?? '-'))).toList(),
                        ),
                        const SizedBox(height: 8),
                        CustomButtonKotak(
                          text: "Tambah/Pilih Etalase",
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PilihEtalasePage(
                                  etalaseList: _etalaseMaster.map((e) => e['nama_etalase'].toString()).toList(),
                                  selectedEtalase: _selectedEtalase.map((e) => e['nama_etalase'].toString()).toList(),
                                ),
                              ),
                            );
                            // Setelah kembali, fetch ulang etalase agar data terbaru
                            await _fetchEtalaseAndAddOn();
                            if (result != null && result is List) {
                              setState(() {
                                _selectedEtalase = _etalaseMaster.where((e) => result.contains(e['nama_etalase'])).toList();
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
                              : _selectedAddOns.map((a) => Chip(label: Text(a['nama_addon'] ?? a['nama'] ?? '-'))).toList(),
                        ),
                        const SizedBox(height: 8),
                        CustomButtonKotak(
                          text: "Tambah/Pilih Add On",
                          onPressed: () async {
                            await _fetchEtalaseAndAddOn(); // fetch ulang add-on sebelum pilih
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddOnListPage(
                                  selectedAddOns: _selectedAddOns,
                                ),
                              ),
                            );
                            if (result != null && result is List) {
                              setState(() {
                                _selectedAddOns = result.map((a) => Map<String, dynamic>.from(a)).toList();
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
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButtonKotak(
                          text: 'Simpan',
                          onPressed: _saveMenu,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButtonKotak(
                          text: 'Hapus',
                          onPressed: _deleteMenu,
                        ),
                      ),
                    ],
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
