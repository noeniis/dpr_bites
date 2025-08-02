import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'halal_page.dart';


class ProsesPengajuanPage extends StatelessWidget {
  final Map<String, dynamic>? initialData;
  const ProsesPengajuanPage({Key? key, this.initialData}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final storeNameController = TextEditingController(text: initialData?['storeName'] ?? '');
    final locationController = TextEditingController(text: initialData?['location'] ?? '');
    final sellerNameController = TextEditingController(text: initialData?['sellerName'] ?? '');
    final phoneNumberController = TextEditingController(text: initialData?['phoneNumber'] ?? '');
    final emailController = TextEditingController(text: initialData?['email'] ?? '');

    // State for validation
    final ValueNotifier<String?> emailError = ValueNotifier(null);
    final ValueNotifier<String?> phoneError = ValueNotifier(null);
    final ValueNotifier<String?> sellerNameError = ValueNotifier(null);

    void validateEmail(String value) {
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
      if (value.isEmpty) {
        emailError.value = 'Email harus diisi';
      } else if (!emailRegex.hasMatch(value)) {
        emailError.value = 'Format email tidak valid';
      } else {
        emailError.value = null;
      }
    }
    void validatePhone(String value) {
      final phoneRegex = RegExp(r"^\d{11,15}");
      if (value.isEmpty) {
        phoneError.value = 'Nomor telepon harus diisi';
      } else if (!phoneRegex.hasMatch(value)) {
        phoneError.value = 'Nomor telepon harus 11-15 digit angka';
      } else {
        phoneError.value = null;
      }
    }
    void validateSellerName(String value) {
      final nameRegex = RegExp(r"^[A-Za-z\s]+");
      if (value.isEmpty) {
        sellerNameError.value = 'Nama penjual harus diisi';
      } else if (!nameRegex.hasMatch(value) || value.contains(RegExp(r"\d"))) {
        sellerNameError.value = 'Nama penjual hanya boleh huruf';
      } else {
        sellerNameError.value = null;
      }
    }

    // Helper untuk update storeData setiap field berubah
    final Map<String, dynamic> storeData = initialData ?? {};
    storeNameController.addListener(() {
      storeData['storeName'] = storeNameController.text;
    });
    locationController.addListener(() {
      storeData['location'] = locationController.text;
    });
    sellerNameController.addListener(() {
      storeData['sellerName'] = sellerNameController.text;
    });
    phoneNumberController.addListener(() {
      storeData['phoneNumber'] = phoneNumberController.text;
    });
    emailController.addListener(() {
      storeData['email'] = emailController.text;
    });

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
          child: Padding(
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
                const SizedBox(height: 20),
                CustomInputField(
                  controller: locationController,
                  hintText: "Lokasi",
                ),
                const SizedBox(height: 24),

                const Text(
                  "Informasi penjual",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String?>(
                  valueListenable: sellerNameError,
                  builder: (context, error, child) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: sellerNameController,
                        decoration: InputDecoration(
                          hintText: "Nama penjual",
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
                        onChanged: (val) {
                          validateSellerName(val);
                          storeData['sellerName'] = val;
                        },
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<String?>(
                  valueListenable: phoneError,
                  builder: (context, error, child) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: phoneNumberController,
                        decoration: InputDecoration(
                          hintText: "Telepon penjual",
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
                        keyboardType: TextInputType.phone,
                        onChanged: (val) {
                          validatePhone(val);
                          storeData['phoneNumber'] = val;
                        },
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<String?>(
                  valueListenable: emailError,
                  builder: (context, error, child) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: "Email penjual",
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
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (val) {
                          validateEmail(val);
                          storeData['email'] = val;
                        },
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButtonKotak(
                      text: "Simpan dan lanjutkan",
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';
                        storeData['userId'] = userId;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HalalPage(storeData: storeData),
                          ),
                        ).then((result) {
                          if (result is Map<String, dynamic>) {
                            storeNameController.text = result['storeName'] ?? '';
                            locationController.text = result['location'] ?? '';
                            sellerNameController.text = result['sellerName'] ?? '';
                            phoneNumberController.text = result['phoneNumber'] ?? '';
                            emailController.text = result['email'] ?? '';
                            // Update storeData juga
                            storeData.addAll(result);
                          }
                        });
                      },
                    ),
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
