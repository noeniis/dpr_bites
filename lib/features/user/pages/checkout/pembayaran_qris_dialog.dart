import 'package:flutter/material.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PembayaranQrisDialog extends StatefulWidget {
  final VoidCallback onKonfirmasi;
  final VoidCallback onBatal;
  const PembayaranQrisDialog({
    Key? key,
    required this.onKonfirmasi,
    required this.onBatal,
  }) : super(key: key);

  @override
  State<PembayaranQrisDialog> createState() => _PembayaranQrisDialogState();
}

class _PembayaranQrisDialogState extends State<PembayaranQrisDialog> {
  XFile? _buktiPembayaran;
  bool _isLoading = false;

  Future<void> _showMissingProofDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Informasi'),
        content: const Text('bukti pembayaran belum di upload'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
                  onPressed: widget.onBatal,
                  tooltip: 'Batal',
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
              child: Image.asset(
                'lib/assets/images/iconQR.png',
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
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
            CustomButtonOval(
              text: 'Konfirmasi',
              onPressed: () async {
                if (_buktiPembayaran == null) {
                  await _showMissingProofDialog();
                  return;
                }
                Navigator.of(context).pop();
                widget.onKonfirmasi();
              },
            ),
          ],
        ),
      ),
    );
  }
}
