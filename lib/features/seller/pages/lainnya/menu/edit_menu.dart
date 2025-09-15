import 'package:dpr_bites/features/seller/models/menu_model.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dpr_bites/features/seller/services/menu_service.dart';
import 'package:dpr_bites/features/seller/services/addon_service.dart';
import '../../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'pilih_etalase_page.dart';
import 'add_on_list_page.dart';
import 'package:dpr_bites/features/seller/models/etalase_model.dart';
import 'package:dpr_bites/features/seller/models/addon_model.dart';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

class EditMenuPage extends StatefulWidget {
  final MenuModel menu;
  final Function(Map<String, dynamic>)? onSave;
  final Function(String)? onDelete;
  const EditMenuPage({Key? key, required this.menu, this.onSave, this.onDelete}) : super(key: key);

  @override
  State<EditMenuPage> createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  final List<String> _kategoriList = ['makanan', 'minuman', 'jajanan'];
  String? _selectedKategori;
  late TextEditingController _namaMenuController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _jumlahStokController;
  List<EtalaseModel> _etalaseMaster = [];
  List<EtalaseModel> _selectedEtalase = [];
  List<AddonModel> _selectedAddOns = [];
  XFile? _menuImage;
  String? _menuImageUrl;
  bool _isTersedia = false;

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    _namaMenuController = TextEditingController(text: menu.namaMenu);
    _deskripsiController = TextEditingController(text: menu.deskripsiMenu);
    _hargaController = TextEditingController(text: menu.harga.toString());
    _jumlahStokController = TextEditingController(text: menu.jumlahStok.toString());

    // Parsing etalase
    if (menu.idEtalase != null && _etalaseMaster.isNotEmpty) {
      _selectedEtalase = _etalaseMaster.where((e) => e.idEtalase == menu.idEtalase).toList();
    } else {
      _selectedEtalase = [];
    }

    // Parsing add_ons
    if (menu.addons != null) {
      _selectedAddOns = menu.addons!;
    } else {
      _selectedAddOns = [];
    }

    // Checkbox tersedia
    _isTersedia = menu.tersedia;

    if (menu.gambarMenu.isNotEmpty) {
      _menuImageUrl = menu.gambarMenu;
    }
    final kategoriDb = menu.kategori.toLowerCase();
    _selectedKategori = _kategoriList.contains(kategoriDb) ? kategoriDb : _kategoriList.first;
    _fetchEtalaseAndAddOn();
  }

  Future<void> _fetchEtalaseAndAddOn() async {
    final idUser = await _secureStorage.read(key: 'id_users');
    if (idUser != null) {
      // Ambil semua etalase master untuk pilihan
      final etalaseList = await MenuService.fetchEtalaseByUser(idUsers: idUser);
      setState(() {
        _etalaseMaster = etalaseList;
      });
      final idGerai = widget.menu.idGerai;
      final idMenu = widget.menu.idMenu;
      final menuDetail = await MenuService.fetchMenuDetail(idGerai: idGerai, idMenu: idMenu);
      if (menuDetail != null) {
        // Etalase
        if (menuDetail['etalase'] != null && (menuDetail['etalase'] as List).isNotEmpty) {
          setState(() {
            _selectedEtalase = (menuDetail['etalase'] as List)
                .map((e) => EtalaseModel.fromJson(e)).toList();
          });
        }
        // Add-on
        if (menuDetail['add_ons'] != null && (menuDetail['add_ons'] as List).isNotEmpty) {
          setState(() {
            _selectedAddOns = (menuDetail['add_ons'] as List)
                .map((a) => AddonModel.fromJson(a)).toList();
          });
        }
      }
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


  Future<void> _saveMenu() async {
    final idMenu = widget.menu.idMenu;
    String gambarMenu = _menuImageUrl ?? '';
    if (_menuImage != null) {
      final url = await AddonService.uploadImageToCloudinary(_menuImage!.path);
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
      'etalase': _selectedEtalase.map((e) => e.idEtalase).join(','),
      'addon': _selectedAddOns.map((a) => a.idAddon).join(','),
      'tersedia': _isTersedia ? '1' : '0',
    };
    final success = await MenuService.updateMenu(bodyData);
    if (success) {
      widget.onSave?.call({...widget.menu.toJson(), ...bodyData});
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal update menu!')),
      );
    }
  }


  Future<void> _deleteMenu() async {
    final idMenu = widget.menu.idMenu;
    final success = await MenuService.deleteMenu(idMenu: idMenu);
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal hapus menu!')),
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
                            ? Image.file(File(_menuImage!.path), width: 100, height: 100, fit: BoxFit.cover)
                            : (_menuImageUrl != null && _menuImageUrl!.isNotEmpty
                                ? Image.network(_menuImageUrl!, width: 100, height: 100, fit: BoxFit.cover)
                                : Image.asset('lib/assets/images/chalkboard_menu.jpeg', width: 100, height: 100, fit: BoxFit.cover)),
                          const SizedBox(height: 8),
                          CustomButtonKotak(
                            text: "Edit Foto",
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setState(() {
                                  _menuImage = pickedFile;
                                });
                              }
                            },
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
                              : _selectedEtalase.map((e) => Chip(label: Text(e.namaEtalase))).toList(),
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
                            await _fetchEtalaseAndAddOn();
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
                              : _selectedAddOns.map((a) => Chip(label: Text(a.namaAddon))).toList(),
                        ),
                        const SizedBox(height: 8),
                        CustomButtonKotak(
                          text: "Tambah/Pilih Add On",
                          onPressed: () async {
                            await _fetchEtalaseAndAddOn();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddOnListPage(
                                  selectedAddOns: _selectedAddOns,
                                ),
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
