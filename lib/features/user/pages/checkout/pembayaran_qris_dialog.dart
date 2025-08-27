import 'package:flutter/material.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PembayaranQrisDialog extends StatefulWidget {
  final void Function(XFile bukti) onKonfirmasi; // return bukti ke parent
  final VoidCallback onBatal; // hanya tutup dialog
  final String? qrisImageUrl; // URL atau path QRIS spesifik gerai
  const PembayaranQrisDialog({
    Key? key,
    required this.onKonfirmasi,
    required this.onBatal,
    this.qrisImageUrl,
  }) : super(key: key);

  @override
  State<PembayaranQrisDialog> createState() => _PembayaranQrisDialogState();
}

class _PembayaranQrisDialogState extends State<PembayaranQrisDialog> {
  XFile? _buktiPembayaran;
  bool _isLoading = false;

  bool get _canConfirm => _buktiPembayaran != null && !_isLoading;

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _buktiPembayaran = image;
      _isLoading = false;
    });
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onBatal();
                  },
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const Text(
              'QRIS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildQrisImage(widget.qrisImageUrl),
            ),
            const SizedBox(height: 18),
            // Input bukti pembayaran
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFD53D3D), width: 1.2),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          _buktiPembayaran != null
                              ? Image.file(
                                  // ignore: prefer_const_constructors
                                  File(_buktiPembayaran!.path),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : Column(
                                  children: const [
                                    Icon(
                                      Icons.upload_file,
                                      color: Color(0xFFD53D3D),
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Upload Bukti Pembayaran',
                                      style: TextStyle(
                                        color: Color(0xFFD53D3D),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Opacity(
              opacity: _canConfirm ? 1 : 0.55,
              child: CustomButtonOval(
                text: 'Konfirmasi',
                onPressed: _canConfirm
                    ? () {
                        final bukti = _buktiPembayaran!;
                        Navigator.of(context).pop();
                        widget.onKonfirmasi(bukti);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildQrisFallback() => Image.asset(
  'lib/assets/images/iconQR.png',
  width: 180,
  height: 180,
  fit: BoxFit.cover,
);

Widget _buildQrisImage(String? url) {
  if (url == null || url.isEmpty) return _buildQrisFallback();
  // Jika bukan absolut, coba treat sebagai relatif ke folder API (uploads)
  if (!url.startsWith('http')) {
    final cleaned = url.startsWith('/') ? url.substring(1) : url;
    final base = 'http://10.0.2.2/dpr_bites_api';
    final full = '$base/$cleaned';
    return Image.network(
      full,
      width: 180,
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildQrisFallback(),
    );
  }
  return Image.network(
    url,
    width: 180,
    height: 180,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => _buildQrisFallback(),
  );
}
