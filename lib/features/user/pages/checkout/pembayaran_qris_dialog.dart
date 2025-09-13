import 'package:flutter/material.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dpr_bites/features/user/services/pembayaran_qris_dialog_service.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:flutter/services.dart';
// Removed image_gallery_saver (AGP 8 namespace issue). Not using gallery_saver due to http version conflict.

class PembayaranQrisDialog extends StatefulWidget {
  final void Function(XFile bukti) onKonfirmasi; // return bukti ke parent
  final VoidCallback onBatal; // hanya tutup dialog
  final String? qrisImageUrl; // URL atau path QRIS spesifik gerai
  final bool showDownload; // tampilkan tombol unduh
  final String? bookingId; // untuk penamaan file unduhan
  final int? totalPembayaran; // total tagihan transaksi (opsional)
  const PembayaranQrisDialog({
    Key? key,
    required this.onKonfirmasi,
    required this.onBatal,
    this.qrisImageUrl,
    this.showDownload = false,
    this.bookingId,
    this.totalPembayaran,
  }) : super(key: key);

  @override
  State<PembayaranQrisDialog> createState() => _PembayaranQrisDialogState();
}

class _PembayaranQrisDialogState extends State<PembayaranQrisDialog> {
  XFile? _buktiPembayaran;
  bool _isLoading = false;
  bool _downloading = false;
  // String? _lastSavedPath; // no longer needed without direct open action

  bool get _canConfirm => _buktiPembayaran != null && !_isLoading;

  String _formatRupiah(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write('.');
        count = 0;
      }
    }
    final rev = buf.toString().split('').reversed.join();
    return 'Rp' + rev;
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

  Future<void> _downloadQris() async {
    if (widget.qrisImageUrl == null || widget.qrisImageUrl!.isEmpty) return;
    if (_downloading) return;
    setState(() => _downloading = true);
    final fullUrl = PembayaranQrisDialogService.buildQrisUrl(
      widget.qrisImageUrl,
    );
    final fileName = widget.bookingId != null && widget.bookingId!.isNotEmpty
        ? 'QRIS_${widget.bookingId}.jpg'
        : null;
    final result = await PembayaranQrisDialogService.downloadQrisImage(
      fullUrl,
      fileName: fileName,
    );
    if (!mounted) return;
    setState(() => _downloading = false);
    if (result.success) {
      // Saved path available if needed: result.localPath
      // Top overlay toast that appears above dialogs
      _showTopToast(message: 'QRIS Gerai Berhasil Diunduh');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message ?? 'Gagal unduh')));
    }
  }

  // Note: "Buka" action removed per request. Users can tap the QRIS image to preview fullscreen.

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
                    Navigator.of(context).pop(); // hanya tutup dialog
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
            GestureDetector(
              onTap: _previewQrisFullScreen,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildQrisImage(widget.qrisImageUrl),
              ),
            ),
            if (widget.totalPembayaran != null) ...[
              const SizedBox(height: 8),
              Text(
                'Total Pembayaran: ' + _formatRupiah(widget.totalPembayaran!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
            ],
            if (widget.showDownload) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB03056),
                    side: const BorderSide(
                      color: Color(0xFFB03056),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _downloading ? null : _downloadQris,
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    _downloading ? 'Mengunduh...' : 'Unduh QRIS',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
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

  void _showTopToast({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.of(ctx).padding.top + 12;
        return Positioned(
          top: top,
          left: 16,
          right: 16,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (_, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * -8),
                child: child,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actionLabel != null && onAction != null)
                      TextButton(
                        onPressed: () {
                          onAction();
                          entry.remove();
                        },
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            color: Color(0xFFB03056),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4)).then((_) {
      if (entry.mounted) entry.remove();
    });
  }

  void _previewQrisFullScreen() {
    final url = widget.qrisImageUrl;
    if (url == null || url.isEmpty) return;
    // Build absolute URL if needed
    final fullUrl = url.startsWith('http')
        ? url
        : PembayaranQrisDialogService.buildQrisUrl(url);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white70,
                      size: 64,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    final full = PembayaranQrisDialogService.buildQrisUrl(url);
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
