import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/seller_user_service.dart';
import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'halal_page.dart';
import 'ktp_form_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'seller_pick_location_page.dart';
import 'package:latlong2/latlong.dart';
import '../../../../common/data/dummy_address.dart';

class ProsesPengajuanPage extends StatefulWidget {
  const ProsesPengajuanPage({super.key});

  @override
  State<ProsesPengajuanPage> createState() => _ProsesPengajuanPageState();
}

class _ProsesPengajuanPageState extends State<ProsesPengajuanPage> {
  final storeNameController = TextEditingController();
  final locationController = TextEditingController();
  final detailAddressController = TextEditingController();
  final sellerNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final optionalPhoneController = TextEditingController();
  final emailController = TextEditingController();
    bool isLoadingUser = true;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final idUsers = prefs.getString('id_users');
    if (idUsers != null) {
      final user = await SellerUserService.fetchUserById(idUsers);
      if (user != null) {
        sellerNameController.text = user['nama_lengkap'] ?? '';
        phoneNumberController.text = user['no_hp'] ?? '';
        emailController.text = user['email'] ?? '';
      }
    }
    setState(() {
      isLoadingUser = false;
    });
  }

  double? selectedLat;
  double? selectedLng;
  String? selectedAddress;

  @override
  void dispose() {
    storeNameController.dispose();
    locationController.dispose();
    detailAddressController.dispose();
    sellerNameController.dispose();
    phoneNumberController.dispose();
    optionalPhoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> handlePickLocation(BuildContext context) async {
    try {
      var status = await Permission.location.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akses lokasi diperlukan untuk memilih lokasi.')),
        );
        return;
      }
      // Ambil area DPR dari dummyAddresses (gunakan min/max lat/lng)
      final dprLatitudes = dummyAddresses
          .where((a) => a.latitude != null)
          .map((a) => a.latitude!)
          .toList();
      final dprLongitudes = dummyAddresses
          .where((a) => a.longitude != null)
          .map((a) => a.longitude!)
          .toList();
      final dprSouthWest = LatLng(
        dprLatitudes.reduce((a, b) => a < b ? a : b),
        dprLongitudes.reduce((a, b) => a < b ? a : b),
      );
      final dprNorthEast = LatLng(
        dprLatitudes.reduce((a, b) => a > b ? a : b),
        dprLongitudes.reduce((a, b) => a > b ? a : b),
      );
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerPickLocationPage(
            dprSouthWest: dprSouthWest,
            dprNorthEast: dprNorthEast,
          ),
        ),
      );
      if (result is Map<String, dynamic> && result['lat'] != null && result['lng'] != null) {
        setState(() {
          selectedLat = result['lat'];
          selectedLng = result['lng'];
          selectedAddress = (result['address'] as String?)?.isNotEmpty == true
              ? result['address']
              : 'Lat: ${selectedLat!.toStringAsFixed(6)}, Lng: ${selectedLng!.toStringAsFixed(6)}';
          locationController.text = selectedAddress!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi error: $e')),
      );
    }
  }

  void showLocationDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail Lokasi'),
        content: Text(selectedAddress ?? '-'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Lengkapi informasi gerai",
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Informasi umum",
                
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                CustomInputField(
                  controller: storeNameController,
                  hintText: "Nama gerai",
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    if (selectedLat != null && selectedLng != null) {
                      showLocationDetail(context);
                    } else {
                      // Jika belum ada lokasi, double tap juga akan handle pick
                      handlePickLocation(context);
                    }
                  },
                  onDoubleTap: () async {
                    await handlePickLocation(context);
                  },
                  child: AbsorbPointer(
                    child: CustomInputField(
                      controller: locationController,
                      hintText: "Pilih lokasi gerai",
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Field Detail Alamat
                CustomInputField(
                  controller: detailAddressController,
                  hintText: "Detail Alamat (misal: Blok, gedung, dsb)",
                ),
                const SizedBox(height: 16),

                const Text(
                  "Informasi penjual",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                  AbsorbPointer(
                    child: CustomInputField(
                      controller: sellerNameController,
                      hintText: "Nama penjual",
                    ),
                  ),
                  const SizedBox(height: 12),
                  AbsorbPointer(
                    child: CustomInputField(
                      controller: phoneNumberController,
                      hintText: "Nomor Handphone",
                    ),
                  ),
                  const SizedBox(height: 12),
                  AbsorbPointer(
                    child: CustomInputField(
                      controller: emailController,
                      hintText: "Email penjual",
                    ),
                  ),
                const SizedBox(height: 12),
                CustomInputField(
                  controller: optionalPhoneController,
                  hintText: "Nomor telepon (opsional)",
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), // Tambah jarak bawah
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: CustomButtonKotak(
                text: "Simpan dan lanjutkan",
                onPressed: () async {
                  final ktpResult = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KtpFormPage()),
                  );
                  if (ktpResult != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HalalPage()),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final List<TextInputFormatter>? inputFormatters;
  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
    );
  }
}
