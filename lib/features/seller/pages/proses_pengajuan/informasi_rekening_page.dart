import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'pengajuan_selesai_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class InformasiRekeningPage extends StatefulWidget {
  final Map<String, dynamic> storeData;
  const InformasiRekeningPage({Key? key, required this.storeData}) : super(key: key);

  @override
  State<InformasiRekeningPage> createState() => _InformasiRekeningPageState();
}

class _InformasiRekeningPageState extends State<InformasiRekeningPage> {
  XFile? qrisImage;
  String? qrisError;

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
      widget.storeData['qrisImagePath'] = image.path;
      // Update storeData agar path QRIS tetap tersimpan
      widget.storeData['qrisImagePath'] = image.path;
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

    // Simpan path lokal QRIS ke Firestore, mirip profile_page
    if (qrisImage != null) {
      final file = File(qrisImage!.path);
      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File QRIS tidak ditemukan di perangkat')),
        );
        return;
      }
      final userId = widget.storeData['userId'] ?? 'unknown';
      final appDir = await getApplicationDocumentsDirectory();
      final qrisPath = '${appDir.path}/stores/seller/$userId/qris.jpg';
      // Pastikan folder ada
      await Directory('${appDir.path}/stores/seller/$userId').create(recursive: true);
      await file.copy(qrisPath);
      data['qrisUrl'] = qrisPath;
    }

    // Simpan ke Firestore
    try {
      await FirebaseFirestore.instance.collection('stores').add(data);
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
