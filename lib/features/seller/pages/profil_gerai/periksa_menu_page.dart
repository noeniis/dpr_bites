import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'dart:io';
import 'package:dpr_bites/features/seller/models/etalase_model.dart';
import 'package:dpr_bites/features/seller/models/menu_model.dart';
import 'package:dpr_bites/features/seller/services/menu_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/features/seller/services/seller_user_service.dart';
import 'package:dpr_bites/features/seller/pages/lainnya/menu/menu_resto.dart';

class PeriksaMenuPage extends StatefulWidget {
  final MenuModel menuModel;
  final List<EtalaseModel> etalase;
  final String? imagePath;

  const PeriksaMenuPage({
    super.key,
    required this.menuModel,
    required this.etalase,
    this.imagePath,
  });

  @override
  State<PeriksaMenuPage> createState() => _PeriksaMenuPageState();
}

class _PeriksaMenuPageState extends State<PeriksaMenuPage> {
  Future<void> _submitMenu(BuildContext context) async {
    final menu = widget.menuModel;
    if (menu.namaMenu.trim().isEmpty ||
        menu.deskripsiMenu.trim().isEmpty ||
        menu.kategori.trim().isEmpty ||
        menu.harga == 0 ||
        menu.jumlahStok == 0 ||
        widget.imagePath == null ||
        widget.imagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib harus diisi dan gambar harus dipilih!')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final idGerai = await MenuService.getIdGerai();
      if (idGerai == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan ID gerai')));
        return;
      }
      int? idEtalase = widget.etalase.isNotEmpty ? widget.etalase[0].idEtalase : null;
      String gambarUrl = '';
      if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
        final url = await MenuService.uploadImageToCloudinary(File(widget.imagePath!));
        if (url == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal upload gambar ke Cloudinary')));
          return;
        }
        gambarUrl = url;
      }
      final menuResult = await MenuService.addMenu(
        idGerai: idGerai,
        idEtalase: idEtalase,
        namaMenu: menu.namaMenu,
        gambarMenu: gambarUrl,
        deskripsiMenu: menu.deskripsiMenu,
        kategori: menu.kategori,
        harga: menu.harga,
        jumlahStok: menu.jumlahStok,
        tersedia: menu.tersedia,
      );
      if (menuResult == null || menuResult['id_menu'] == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan menu: ${menuResult?['error'] ?? 'Unknown error'}')),
        );
        return;
      }
      final idMenu = menuResult['id_menu'] is int
          ? menuResult['id_menu']
          : int.tryParse(menuResult['id_menu'].toString());
      if (menu.addons != null && menu.addons!.isNotEmpty) {
        final idAddons = menu.addons!
            .map((e) => e.idAddon)
            .where((id) => id > 0)
            .toList();
        if (idAddons.isNotEmpty) {
          await MenuService.addMenuAddons(idMenu: idMenu!, idAddons: idAddons);
        }
      }
      // Update step3 menjadi 1
      try {
        final storage = FlutterSecureStorage();
        final idUsers = await storage.read(key: 'id_users');
        if (idUsers != null) {
          await SellerUserService.updateStepSellerStatus(idUsers, step3: 1);
        }
      } catch (e) {
        debugPrint('Gagal update step3: $e');
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu berhasil ditambahkan!')));
      // Navigasi ke halaman MenuRestoPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MenuRestoPage()),
        (route) => false,
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
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
            icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Periksa Menu",
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Afacad',
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar Menu
                  widget.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.imagePath!),
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                          ),
                          child: const Center(child: Text("Belum ada gambar")),
                        ),
                  const SizedBox(height: 20),

                  Text("Nama hidangan", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.menuModel.namaMenu, style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 16),
                  Text("Kategori", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.menuModel.kategori, style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 16),
                  Text("Harga", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Rp ${widget.menuModel.harga}", style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 16),
                  Text("Deskripsi", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.menuModel.deskripsiMenu, textAlign: TextAlign.justify, style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 16),
                  Text("Stok", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.menuModel.jumlahStok.toString(), style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 16),
                  Text("Status", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.menuModel.tersedia ? 'Tersedia' : 'Tidak tersedia', style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 16),
                  Text("Etalase", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  widget.etalase.isEmpty
                      ? const Text('Belum ada etalase dipilih', style: TextStyle(color: Colors.black54))
                      : Wrap(
                          spacing: 8,
                          children: widget.etalase
                              .map((e) => Chip(label: Text(e.namaEtalase)))
                              .toList(),
                        ),
                  const SizedBox(height: 16),
                  Text("Add On", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  (widget.menuModel.addons == null || widget.menuModel.addons!.isEmpty)
                      ? const Text('Belum ada add on', style: TextStyle(color: Colors.black54))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.menuModel.addons!.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(child: Text(e.namaAddon, style: const TextStyle(fontSize: 16))),
                                  Text('Stok: ${e.stok}', style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: CustomButtonKotak(
                text: "Buat menu",
                onPressed: () => _submitMenu(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
