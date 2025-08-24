import 'package:dpr_bites/features/seller/pages/lainnya/menu/menu_resto.dart';
import 'package:dpr_bites/features/seller/services/menu_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';


class PeriksaMenuPage extends StatelessWidget {
  Future<void> _submitMenu(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      // 1. Get id_gerai
      final idGerai = await MenuService.getIdGerai();
      if (idGerai == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan ID gerai')));
        return;
      }

      // 2. Get id_etalase utama (ambil yang pertama saja)
      int? idEtalase;
      List<Map<String, dynamic>> etalaseList = [];
      // Ambil etalaseList dari API (atau cache) agar dapat id_etalase
      final prefs = await SharedPreferences.getInstance();
      final etalaseJson = prefs.getString('etalase_list');
      if (etalaseJson != null) {
        etalaseList = List<Map<String, dynamic>>.from(jsonDecode(etalaseJson));
      } else {
        // fallback: ambil dari API jika belum ada di prefs
        final response = await http.get(Uri.parse('${getBaseUrl()}/get_etalase.php?id_gerai=$idGerai'));
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['etalase'] != null) {
          etalaseList = List<Map<String, dynamic>>.from(data['etalase']);
          prefs.setString('etalase_list', jsonEncode(etalaseList));
        }
      }
      if (etalase.isNotEmpty && etalaseList.isNotEmpty) {
        final selectedNama = etalase[0];
        final found = etalaseList.firstWhere(
          (e) => e['nama_etalase'] == selectedNama,
          orElse: () => {},
        );
        idEtalase = found['id_etalase'] is int
            ? found['id_etalase']
            : int.tryParse(found['id_etalase']?.toString() ?? '');
      }

      // 3. Upload gambar ke Cloudinary jika ada
      String gambarUrl = '';
      if (imagePath != null && imagePath!.isNotEmpty) {
        final url = await MenuService.uploadImageToCloudinary(File(imagePath!));
        if (url == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal upload gambar ke Cloudinary')));
          return;
        }
        gambarUrl = url;
      }

      // 4. Kirim data menu ke API
      final menuResult = await MenuService.addMenu(
        idGerai: idGerai,
        idEtalase: idEtalase,
        namaMenu: namaMenu,
        gambarMenu: gambarUrl,
        deskripsiMenu: deskripsi,
        kategori: kategori,
        harga: int.tryParse(harga) ?? 0,
        jumlahStok: int.tryParse(jumlahStok) ?? 0,
        tersedia: isTersedia,
      );
      if (menuResult == null || menuResult['id_menu'] == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan menu ke database')));
        return;
      }
      final idMenu = menuResult['id_menu'] is int ? menuResult['id_menu'] : int.tryParse(menuResult['id_menu'].toString());

      // 5. Jika ada add on, simpan ke menu_addon
      if (addOns.isNotEmpty) {
        print('DEBUG addOns:');
        for (var e in addOns) {
          print(e);
          print('DEBUG nama_addon: [32m[1m' + (e['nama_addon']?.toString() ?? e['nama']?.toString() ?? '-') + '\u001b[0m');
        }
        final idAddons = addOns.map((e) => int.tryParse(e['id_addon'].toString()) ?? 0).where((id) => id > 0).toList();
        print('DEBUG idAddons: $idAddons');
        if (idAddons.isNotEmpty) {
          await MenuService.addMenuAddons(idMenu: idMenu, idAddons: idAddons);
        }
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu berhasil ditambahkan!')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuRestoPage()),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
    }
  }
  final String namaMenu;
  final String deskripsi;
  final String harga;
  final String jumlahStok;
  final String kategori;
  final List<String> etalase;
  final List<Map<String, dynamic>> addOns;
  final String? imagePath;
  final bool isTersedia;

  const PeriksaMenuPage({
    super.key,
    required this.namaMenu,
    required this.deskripsi,
    required this.harga,
    required this.jumlahStok,
    required this.kategori,
    required this.etalase,
    required this.addOns,
    this.imagePath,
    required this.isTersedia,
  });

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
              Navigator.pop(context);
            },
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
                  imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(imagePath!),
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
                  Text("Nama hidangan", style: TextStyle(fontFamily: 'Afacad', fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(namaMenu, style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black)),
                  const SizedBox(height: 16),
                  Text("Kategori", style: TextStyle(fontFamily: 'Afacad', fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(kategori, style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black)),
                  const SizedBox(height: 16),
                  Text("Harga", style: TextStyle(fontFamily: 'Afacad', fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Rp $harga", style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black)),
                  const SizedBox(height: 16),
                  Text("Deskripsi", style: TextStyle(fontFamily: 'Afacad', fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(deskripsi, textAlign: TextAlign.justify, style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black)),
                  const SizedBox(height: 16),
                  Text("Stok", style: TextStyle(fontFamily: 'Afacad', fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(jumlahStok, style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black)),
                  const SizedBox(height: 16),
                  Text("Status", style: TextStyle(fontFamily: 'Afacad', fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(isTersedia ? 'Tersedia' : 'Tidak tersedia', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black)),
                  const SizedBox(height: 16),
                  Text("Etalase", style: TextStyle(fontFamily: 'Afacad', fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  etalase.isEmpty
                      ? const Text('Belum ada etalase dipilih', style: TextStyle(color: Colors.black54))
                      : Wrap(spacing: 8, children: etalase.map((e) => Chip(label: Text(e))).toList()),
                  const SizedBox(height: 16),
                  Text("Add On", style: TextStyle(fontFamily: 'Afacad', fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  addOns.isEmpty
                      ? const Text('Belum ada add on', style: TextStyle(color: Colors.black54))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: addOns.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(e['nama_addon'] ?? e['nama'] ?? '-', style: TextStyle(fontFamily: 'Inter', fontSize: 16))),
                                Text('Stok: ${e['stok'] ?? '-'}', style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
                              ],
                            ),
                          )).toList(),
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
