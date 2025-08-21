import 'package:flutter/material.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class AlamatPengantaranDialog extends StatefulWidget {
  final String? initialNama;
  final String? initialDetail;
  const AlamatPengantaranDialog({Key? key, this.initialNama, this.initialDetail}) : super(key: key);

  @override
  State<AlamatPengantaranDialog> createState() => _AlamatPengantaranDialogState();
}

class _AlamatPengantaranDialogState extends State<AlamatPengantaranDialog> {
  late TextEditingController namaController;
  late TextEditingController detailController;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.initialNama ?? '');
    detailController = TextEditingController(text: widget.initialDetail ?? '');
  }

  @override
  void dispose() {
    namaController.dispose();
    detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'Alamat Pengantaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Nama Ruangan/Gedung
            TextField(
              controller: namaController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.home_outlined, color: Color(0xFFD53D3D)),
                hintText: 'Nama Ruangan',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 14),
            // Detail Lokasi
            TextField(
              controller: detailController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFFD53D3D)),
                hintText: 'Detail Lokasi',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 18),
            CustomButtonOval(
              text: 'Konfirmasi',
              onPressed: () {
                Navigator.of(context).pop({
                  'nama': namaController.text,
                  'detail': detailController.text,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
