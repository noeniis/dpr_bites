
import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'pengajuan_selesai_page.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/qris_service.dart';

class InformasiRekeningPage extends StatefulWidget {
  const InformasiRekeningPage({super.key});

  @override
  State<InformasiRekeningPage> createState() => _InformasiRekeningPageState();
}

class _InformasiRekeningPageState extends State<InformasiRekeningPage> {
  final _storage = FlutterSecureStorage();
  String? _qrisUrlFromDb;
  @override
  void initState() {
    super.initState();
    _fetchQrisFromDb();
  }

  Future<void> _fetchQrisFromDb() async {
    final idUsers = await _storage.read(key: 'id_users') ?? '';
    if (idUsers.isEmpty) return;
    final qrisUrl = await QrisService.getQrisUrlByUser(idUsers);
    if (qrisUrl != null && qrisUrl.isNotEmpty) {
      setState(() {
        _qrisUrlFromDb = qrisUrl;
      });
    }
  }
  bool _isLoading = false;

  Future<void> _handleKirim() async {
    if (_qrisImage == null && _qrisUrlFromDb != null && _qrisUrlFromDb!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PengajuanSelesaiPage()),
      );
      return;
    }
    if (_qrisImage != null) {
      setState(() => _isLoading = true);
      final success = await QrisService.uploadAndSaveQris(_qrisImage);
      setState(() => _isLoading = false);
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PengajuanSelesaiPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal upload/simpan QRIS')),);
      }
      return;
    }
    // Jika tidak ada gambar sama sekali
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Silakan upload gambar QRIS terlebih dahulu.')),
    );
  }
  XFile? _qrisImage;

  Future<void> _pickQrisImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _qrisImage = image;
      });
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
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Qris Penjual",
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Afacad',
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const Text(
                  "Upload gambar QRIS yang dimiliki penjual untuk pembayaran digital.",
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: DottedBorderContainer(
                    child: _qrisImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_qrisImage!.path),
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          )
                        : (_qrisUrlFromDb != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _qrisUrlFromDb!,
                                  height: 180,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : const Icon(Icons.qr_code_2, size: 80, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _pickQrisImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Upload QRIS dari Galeri"),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading ? null : (_qrisImage != null || (_qrisUrlFromDb != null && _qrisUrlFromDb!.isNotEmpty) ? _handleKirim : null),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Kirim", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

class DottedBorderContainer extends StatelessWidget {
  final Widget child;
  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: AppTheme.primaryColor, radius: 16),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          pathMetric.extractPath(distance, next),
          paint,
        );
        distance = next + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
