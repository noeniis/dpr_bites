import 'package:dpr_bites/features/seller/services/addon_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class EditAddonPage extends StatefulWidget {
  final Map<String, dynamic> addon;
  final Function(Map<String, dynamic>)? onSave;
  final Function(String)? onDelete;
  const EditAddonPage({Key? key, required this.addon, this.onSave, this.onDelete}) : super(key: key);

  @override
  State<EditAddonPage> createState() => _EditAddonPageState();
}

class _EditAddonPageState extends State<EditAddonPage> {
  late TextEditingController _namaAddonController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  XFile? _addonImage;
  String? _addonImageUrl;
  bool _isTersedia = false;
  late TextEditingController _stokController;

  @override
  void initState() {
    super.initState();
    final addon = widget.addon;
    _namaAddonController = TextEditingController(text: (addon['nama_addon'] ?? addon['nama'])?.toString() ?? '');
    _deskripsiController = TextEditingController(text: (addon['deskripsi'] ?? addon['desc'])?.toString() ?? '');
    _hargaController = TextEditingController(text: (addon['harga'] ?? addon['harga'])?.toString() ?? '');
  _stokController = TextEditingController(text: (addon['stok'] ?? addon['stok'])?.toString() ?? '0');
    if (addon['image_path'] != null && addon['image_path'].toString().isNotEmpty) {
      _addonImageUrl = addon['image_path'];
    }
    final tersediaVal = addon['tersedia'];
    _isTersedia = tersediaVal == true || tersediaVal == 1 || tersediaVal == '1';
  }

  @override
  void dispose() {
    _namaAddonController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  Future<void> _pickAddonImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _addonImage = image;
      });
    }
  }

  Future<void> _saveAddon() async {
    final idAddon = widget.addon['id_addon'] ?? widget.addon['id'] ?? '';
    String gambarAddon = _addonImageUrl ?? '';
    if (_addonImage != null) {
      final url = await AddonService.uploadImageToCloudinary(_addonImage!.path);
      if (url != null) {
        gambarAddon = url;
      }
    }
    
    final success = await AddonService.updateAddonWithImage(
      idAddon: int.tryParse(idAddon.toString()) ?? 0,
      namaAddon: _namaAddonController.text,
      deskripsi: _deskripsiController.text,
      harga: int.tryParse(_hargaController.text) ?? 0,
      imagePath: gambarAddon,
      tersedia: _isTersedia,
      stok: int.tryParse(_stokController.text) ?? 0,
    );
    if (success) {
      widget.onSave?.call({...widget.addon,
        'nama_addon': _namaAddonController.text,
        'harga': _hargaController.text,
        'tersedia': _isTersedia ? '1' : '0',
        'image_path': gambarAddon,
        'deskripsi': _deskripsiController.text,
        'stok': _stokController.text,
      });
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal update add-on!')),
      );
    }
  }

  Future<void> _deleteAddon() async {
    final idAddon = widget.addon['id_addon'] ?? widget.addon['id'] ?? '';
  final success = await AddonService.deleteAddonWithImage(idAddon: int.tryParse(idAddon.toString()) ?? 0);
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal hapus add-on!')),
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
            "Edit Add-On",
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
                        const Text(
                          "Nama Add-On",
                          style: TextStyle(fontSize: 16, fontFamily: 'Inter', color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _namaAddonController,
                          decoration: const InputDecoration(
                            hintText: "Beri nama add-on",
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
                        const Text(
                          "Foto Add-On",
                          style: TextStyle(fontSize: 16, fontFamily: 'Inter', color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 6),
                        _addonImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_addonImage!.path),
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (_addonImageUrl != null && _addonImageUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _addonImageUrl!,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(child: Text("Belum ada gambar")),
                                  ),
                        const SizedBox(height: 8),
                        CustomButtonKotak(
                          text: "Pilih gambar",
                          onPressed: _pickAddonImage,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Ukuran gambar maksimal 2 MB. Pastikan kualitas gambar jelas dan menggugah selera.",
                          style: TextStyle(fontSize: 16, fontFamily: 'Inter', color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Deskripsi",
                          style: TextStyle(fontSize: 16, fontFamily: 'Inter', color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _deskripsiController,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            hintText: "Masukkan deskripsi add-on ini",
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
                        const Text(
                          "Harga",
                          style: TextStyle(fontSize: 16, fontFamily: 'Inter', color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _hargaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Rp Masukkan harga add-on",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Stok",
                          style: TextStyle(fontSize: 16, fontFamily: 'Inter', color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _stokController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Masukkan jumlah stok",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Ketersediaan",
                          style: TextStyle(fontSize: 16, fontFamily: 'Inter', color: Color(0xFF333333)),
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
                          text: "Simpan",
                          onPressed: _saveAddon,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButtonKotak(
                          text: "Hapus",
                          onPressed: _deleteAddon,
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
