import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'halal_page.dart';

class ProsesPengajuanPage extends StatelessWidget {
  const ProsesPengajuanPage({super.key});

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

                Center(
                  child: CustomButtonKotak(
                    text: "Simpan dan lanjutkan",
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HalalPage()),
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

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
