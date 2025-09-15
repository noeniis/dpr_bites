import 'package:dpr_bites/features/seller/pages/profil_gerai/periksa_menu_page.dart';
import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/features/seller/models/etalase_model.dart';
import 'package:dpr_bites/features/seller/models/menu_model.dart';
import 'package:dpr_bites/features/seller/models/addon_model.dart';
import 'package:dpr_bites/features/seller/services/etalase_service.dart';
import '../lainnya/menu/pilih_etalase_page.dart';
import '../lainnya/menu/add_on_list_page.dart';

class TambahMenuPage extends StatefulWidget {
  const TambahMenuPage({super.key});

  @override
  TambahMenuPageState createState() => TambahMenuPageState();
}

class TambahMenuPageState extends State<TambahMenuPage> {
  List<AddonModel> _selectedAddOns = [];
  // List<EtalaseModel> _etalaseList = []; // tidak dipakai
  List<EtalaseModel> _selectedEtalase = [];

  @override
  void initState() {
    super.initState();
    _fetchEtalase();
  }

  Future<void> _fetchEtalase() async {
    final storage = FlutterSecureStorage();
    final idGerai = await storage.read(key: 'id_gerai');
    if (idGerai != null) {
      await EtalaseService.fetchEtalase(idGerai: int.parse(idGerai));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('id_gerai tidak ditemukan. Silakan selesaikan onboarding atau login ulang.')),
        );
      });
    }
  }

  XFile? _menuImage;

  final TextEditingController _namaMenuController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _jumlahStokController = TextEditingController();
  bool _isTersedia = false;
  String? _selectedKategori;

  Future<void> _pickMenuImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _menuImage = image;
      });
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  value: _selectedKategori,
                  items: <String>['Makanan', 'Minuman', 'Jajanan']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  },
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Etalase
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
                      ? [
                          const Text('Belum ada etalase dipilih',
                              style: TextStyle(color: Colors.black54))
                        ]
                      : _selectedEtalase
                          .map((e) => Chip(label: Text(e.namaEtalase)))
                          .toList(),
                ),
                const SizedBox(height: 8),
                CustomButtonKotak(
                  text: "Tambah/Pilih Etalase",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PilihEtalasePage(
                          selectedEtalase: _selectedEtalase,
                        ),
                      ),
                    );
                    if (result != null && result is List<EtalaseModel>) {
                      setState(() {
                        _selectedEtalase = result;
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      ? [
                          const Text('Belum ada add on',
                              style: TextStyle(color: Colors.black54))
                        ]
                      : _selectedAddOns
                          .map((e) => Chip(label: Text(e.namaAddon)))
                          .toList(),
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
                    if (result != null && result is List<AddonModel>) {
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
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonKotak(
                    text: "Periksa menu",
                    onPressed: () {
                      final menuModel = MenuModel(
                        idMenu: 0,
                        idGerai: 0,
                        idEtalase: _selectedEtalase.isNotEmpty ? _selectedEtalase[0].idEtalase : null,
                        namaMenu: _namaMenuController.text,
                        gambarMenu: '', // gambar diupload di PeriksaMenuPage
                        deskripsiMenu: _deskripsiController.text,
                        kategori: _selectedKategori ?? '',
                        harga: int.tryParse(_hargaController.text) ?? 0,
                        jumlahStok: int.tryParse(_jumlahStokController.text) ?? 0,
                        tersedia: _isTersedia,
                        addons: _selectedAddOns,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PeriksaMenuPage(
                            menuModel: menuModel,
                            etalase: _selectedEtalase,
                            imagePath: _menuImage?.path,
                          ),
                        ),
                      );
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
