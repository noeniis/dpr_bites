import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'pengajuan_selesai_page.dart';

class InformasiRekeningPage extends StatefulWidget {
  final Map<String, dynamic> storeData;
  const InformasiRekeningPage({Key? key, required this.storeData}) : super(key: key);

  @override
  State<InformasiRekeningPage> createState() => _InformasiRekeningPageState();
}

class _InformasiRekeningPageState extends State<InformasiRekeningPage> {
  XFile? qrisImage;
  String? qrisError;

  final String cloudName = 'dip8i3f6x';
  final String uploadPreset = 'dpr_bites';

  @override
  void initState() {
    super.initState();
    final existingPath = widget.storeData['qrisImagePath'];
    if (existingPath != null) {
      qrisImage = XFile(existingPath);
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
            onPressed: () {
              if (qrisImage != null) {
                widget.storeData['qrisImagePath'] = qrisImage!.path;
              }
              Navigator.pop(context, widget.storeData);
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upload QRIS Toko Anda",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text("Pilih Gambar QRIS"),
                  onPressed: _pickQrisImage,
                ),
                const SizedBox(height: 16),
                if (qrisImage != null)
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Image.file(
                        File(qrisImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (qrisError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(qrisError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButtonKotak(
                      text: "Kirim",
                      onPressed: _submitData,
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

  Future<void> _pickQrisImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        qrisImage = image;
        qrisError = null;
      });
    }
  }

  bool _validate() {
    setState(() {
      qrisError = qrisImage == null ? 'QRIS harus diupload' : null;
    });
    return qrisError == null;
  }

  Future<void> _submitData() async {
    if (!_validate()) return;

    final data = Map<String, dynamic>.from(widget.storeData);
    data['createdAt'] = DateTime.now();

    final userId = widget.storeData['userId'] ?? 'unknown_user';

    // Upload gambar ke Cloudinary
    if (qrisImage != null) {
      final file = File(qrisImage!.path);
      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File QRIS tidak ditemukan di perangkat')),
        );
        return;
      }

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['public_id'] = 'stores/$userId/qris' // path rapi
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final result = json.decode(resStr);
        final imageUrl = result['secure_url'];
        final cloudinaryId = result['public_id'];

        data['qrisUrl'] = imageUrl;
        data['cloudinaryId'] = cloudinaryId;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal upload gambar QRIS ke Cloudinary')),
        );
        return;
      }
    }

    // Simpan ke Firestore dengan path: stores/{userId}
    try {
      await FirebaseFirestore.instance.collection('stores').doc(userId).set(data);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PengajuanSelesaiPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data: $e')),
      );
    }
  }
}
