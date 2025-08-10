import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'halal_page.dart';
import 'package:dpr_bites/features/seller/pages/pick_map_page.dart';
import 'package:latlong2/latlong.dart'; // Import LatLng

class ProsesPengajuanPage extends StatefulWidget {
  const ProsesPengajuanPage({super.key});

  @override
  ProsesPengajuanPageState createState() => ProsesPengajuanPageState();
}

class ProsesPengajuanPageState extends State<ProsesPengajuanPage> {
  // Variabel untuk menyimpan lokasi yang dipilih
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    final storeNameController = TextEditingController();
    final locationController = TextEditingController();
    final sellerNameController = TextEditingController();
    final phoneNumberController = TextEditingController();
    final emailController = TextEditingController();

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
                CustomInputField(
                  controller: locationController,
                  hintText: "Lokasi",
                ),
                const SizedBox(height: 16),

                // Tombol pilih lokasi
                ElevatedButton(
                  onPressed: () async {
                    final location = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PickMapPage()),
                    );

                    if (location != null) {
                      setState(() {
                        selectedLocation = location; // Simpan lokasi
                      });
                    }
                  },
                  child: const Text('Pilih Lokasi di Peta'),
                ),
                if (selectedLocation != null)
                  Text(
                    'Lokasi: Lat: ${selectedLocation!.latitude}, Lng: ${selectedLocation!.longitude}',
                    style: const TextStyle(fontSize: 16),
                  ),

                const SizedBox(height: 16),

                const Text(
                  "Informasi penjual",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                CustomInputField(
                  controller: sellerNameController,
                  hintText: "Nama penjual",
                ),
                const SizedBox(height: 12),
                CustomInputField(
                  controller: phoneNumberController,
                  hintText: "Telepon penjual",
                ),
                const SizedBox(height: 12),
                CustomInputField(
                  controller: emailController,
                  hintText: "Email penjual",
                ),
                const SizedBox(height: 32),

                // Tombol Simpan dan lanjutkan
                Center(
                  child: CustomButtonKotak(
                    text: "Simpan dan lanjutkan",
                    onPressed: () {
                      if (selectedLocation != null) {
                        (
                          'Lokasi Gerai: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HalalPage()),
                        );
                      } else {
                        ('Lokasi belum dipilih!');
                      }
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
