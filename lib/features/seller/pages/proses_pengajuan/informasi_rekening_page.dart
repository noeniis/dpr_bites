import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'pengajuan_selesai_page.dart';
import 'dart:io';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dpr_bites/features/seller/services/menu_service.dart';

class InformasiRekeningPage extends StatefulWidget {
  const InformasiRekeningPage({super.key});

  @override
  State<InformasiRekeningPage> createState() => _InformasiRekeningPageState();
}

class _InformasiRekeningPageState extends State<InformasiRekeningPage> {
  XFile? _qrisImage;

  // NEW: guard supaya tidak dobel submit
  bool _isSubmitting = false;

  String getBaseUrl() {
    // Emulator Android = 10.0.2.2 ; HP fisik wajib pakai IP LAN PC
    return 'http://10.78.187.182:80/dpr_bites_api';
  }

  Future<void> _pickQrisImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _qrisImage = image;
      });
    }
  }

  Future<void> _submitPenjualInfo() async {
    if (_isSubmitting) {
      debugPrint('[QRIS] Skip: masih mengirim');
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      String? idUsers = prefs.getString('id_users');
      String? idGerai = prefs.getString('id_gerai');

      // Log apa adanya di prefs
      debugPrint("[QRIS] prefs.id_users=$idUsers prefs.id_gerai=$idGerai");

      // Fallback jika id_gerai tidak ada
      if (idGerai == null || idGerai.isEmpty) {
        final gid = await MenuService.getIdGerai();
        if (gid != null) {
          idGerai = gid.toString();
          await prefs.setString('id_gerai', idGerai);
          debugPrint('[QRIS] id_gerai fallback dari service: $idGerai');
        }
      }

      // Validasi id
      if (idUsers == null || idGerai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('id_users atau id_gerai belum tersedia'),
          ),
        );
        return;
      }

      // Validasi QRIS Image
      if (_qrisImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan upload gambar QRIS terlebih dahulu.'),
          ),
        );
        return;
      }

      // Upload QRIS ke Cloudinary
      final qrisUrl = await MenuService.uploadImageToCloudinary(
        File(_qrisImage!.path),
      );
      debugPrint('[QRIS] Cloudinary URL: $qrisUrl');

      // Susun payload (lengkap)
      final payload = {
        'id_users': int.tryParse(idUsers) ?? 0,
        'id_gerai': int.tryParse(idGerai) ?? 0,

        // dari ProsesPengajuanPage
        'nama_gerai': prefs.getString('penjual_nama_gerai') ?? '',
        'latitude': prefs.getDouble('penjual_lat') ?? 0.0,
        'longitude': prefs.getDouble('penjual_lng') ?? 0.0,
        'detail_alamat': prefs.getString('penjual_detail_alamat') ?? '',

        // dari user/ktp form
        'nama_penjual': prefs.getString('penjual_nama_penjual') ?? '',
        'no_telepon_penjual': prefs.getString('penjual_no_hp') ?? '',
        'email_penjual': prefs.getString('penjual_email') ?? '',
        'nomor_opsional': prefs.getString('penjual_nomor_opsional') ?? '',
        'nik': prefs.getString('penjual_nik') ?? '',
        'jenis_kelamin': prefs.getString('penjual_jenis_kelamin') ?? '',
        'tempat_lahir': prefs.getString('penjual_tempat_lahir') ?? '',
        'tanggal_lahir': prefs.getString('penjual_tanggal_lahir') ?? '',
        'foto_ktp_path': prefs.getString('penjual_foto_ktp_url') ?? '',

        // dari HalalPage
        'sertifikasi_halal':
            prefs.getString('penjual_sertifikasi_halal') ?? 'Tidak',

        // halaman ini
        'qris_path': qrisUrl ?? '',
      };

      // Log ringkas agar gak kepanjangan
      debugPrint('[QRIS] POST ${getBaseUrl()}/penjual_info.php');
      debugPrint(
        '[QRIS] Payload ringkas: ${jsonEncode({'id_users': payload['id_users'], 'id_gerai': payload['id_gerai'], 'nama_gerai': payload['nama_gerai'], 'qris_path': payload['qris_path']})}',
      );

      // Validasi minimal yang kamu mau
      if ((payload['nama_gerai'] as String).isEmpty ||
          (payload['no_telepon_penjual'] as String).isEmpty ||
          (payload['nik'] as String).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beberapa field wajib masih kosong')),
        );
        return;
      }

      // Kirim ke PHP (log hasilnya)
      final resp = await http
          .post(
            Uri.parse('${getBaseUrl()}/penjual_info.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      debugPrint('[QRIS] resp.status=${resp.statusCode}');
      debugPrint('[QRIS] resp.body=${resp.body}');

      if (!mounted) return;
      if (resp.statusCode == 200) {
        final res = jsonDecode(resp.body);
        if (res is Map && res['status'] == 'success') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PengajuanSelesaiPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['message']?.toString() ?? 'Gagal menyimpan data penjual',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTTP ${resp.statusCode}: ${resp.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Tampilkan dialog error jaringan
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Gagal Terhubung'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      debugPrint('[QRIS] Exception: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                  style: TextStyle(fontSize: 15, color: AppTheme.textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: DottedBorderContainer(
                    child: _qrisImage == null
                        ? const Icon(
                            Icons.qr_code_2,
                            size: 80,
                            color: Colors.grey,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_qrisImage!.path),
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
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
                      onPressed: _isSubmitting
                          ? null
                          : _submitPenjualInfo, // NEW: disable saat submit
                      child: Text(
                        _isSubmitting ? "Mengirim..." : "Kirim",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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
          painter: _DashedBorderPainter(
            color: AppTheme.primaryColor,
            radius: 16,
          ),
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
        canvas.drawPath(pathMetric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
