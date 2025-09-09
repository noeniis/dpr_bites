import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';

class KtpCameraPage extends StatefulWidget {
  const KtpCameraPage({super.key});

  @override
  State<KtpCameraPage> createState() => _KtpCameraPageState();
}

class _KtpCameraPageState extends State<KtpCameraPage> {
  CameraController? _controller;
  XFile? _capturedFile;
  bool _isReady = false;
  bool _isBusy = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMsg = 'Tidak ada kamera yang tersedia.');
        return;
      }
      final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      _controller = CameraController(camera, ResolutionPreset.high);
      await _controller!.initialize();
      setState(() => _isReady = true);
    } catch (e) {
      setState(() => _errorMsg = 'Gagal mengakses kamera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _ocrKtp(String imagePath) async {
  final inputImage = InputImage.fromFilePath(imagePath);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  final text = recognizedText.text;

    String nik = '';
    String nama = '';
    String gender = '';
    String tempatLahir = '';
    String tanggalLahir = '';

    final lines = text.split('\n');
    int nikIdx = -1, namaIdx = -1, ttlIdx = -1;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toUpperCase();
      // NIK: setelah KABUPATEN/KOTA
      if (nik.isEmpty && (line.contains('KABUPATEN') || line.contains('KOTA')) && i + 1 < lines.length) {
        final next = lines[i + 1].replaceAll(RegExp(r'[^0-9]'), '');
        if (next.length >= 12 && next.length <= 20) {
          nik = next;
          nikIdx = i + 1;
        }
      }
      // Nama: setelah AGAMA/GAMA
      if (nama.isEmpty && (line.contains('AGAMA') || line.contains('GAMA')) && i + 1 < lines.length) {
        final next = lines[i + 1].trim();
        if (next.isNotEmpty) {
          nama = next;
          namaIdx = i + 1;
        }
      }
    }
    // Tempat/Tgl Lahir: setelah nama
    if (namaIdx != -1 && namaIdx + 1 < lines.length) {
      final next = lines[namaIdx + 1].trim();
      final parts = next.split(',');
      if (parts.isNotEmpty) {
        tempatLahir = parts[0].replaceAll(RegExp(r'[^A-Z ]', caseSensitive: false), '').trim();
        if (parts.length > 1) {
          tanggalLahir = parts[1].replaceAll(RegExp(r'[^0-9-]'), '').trim();
        }
        ttlIdx = namaIdx + 1;
      }
    }
    // Jenis kelamin: setelah tempat/tgl lahir
    if (ttlIdx != -1 && ttlIdx + 1 < lines.length) {
      final next = lines[ttlIdx + 1].toUpperCase();
      if (next.contains('PEREMPUAN')) gender = 'Perempuan';
      if (next.contains('LAKI')) gender = 'Laki-laki';
    }
    return {
      'nik': nik,
      'nama': nama,
      'gender': gender,
      'tempatLahir': tempatLahir,
      'tanggalLahir': tanggalLahir,
    };
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isBusy = true);
    final file = await _controller!.takePicture();

    // Baca gambar asli
    final originalBytes = await File(file.path).readAsBytes();
    final originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) {
      setState(() {
        _capturedFile = file;
        _isBusy = false;
      });
      return;
    }

    // Hitung area crop sesuai kotak KTP di tengah preview
    final previewAspect = 85.6 / 53.98;
    final imgW = originalImage.width;
    final imgH = originalImage.height;
    double cropW, cropH;
    if (imgW / imgH > previewAspect) {
      cropH = imgH * 0.7;
      cropW = cropH * previewAspect;
    } else {
      cropW = imgW * 0.9;
      cropH = cropW / previewAspect;
    }
    final cropX = ((imgW - cropW) / 2).round();
    final cropY = ((imgH - cropH) / 2).round();
    final cropWidth = cropW.round();
    final cropHeight = cropH.round();

    final cropped = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final croppedPath = file.path.replaceFirst('.jpg', '_crop.jpg').replaceFirst('.png', '_crop.png');
    final croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 95));

    // OCR hasil crop
    final ocrResult = await _ocrKtp(croppedFile.path);

    setState(() {
      _capturedFile = XFile(croppedFile.path);
      _isBusy = false;
    });

    // Kirim hasil OCR ke halaman sebelumnya
    Navigator.pop(context, {
      'imagePath': croppedFile.path,
      'ocr': ocrResult,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text('Foto KTP', style: TextStyle(color: Colors.white)),
      ),
      body: _errorMsg != null
          ? Center(child: Text(_errorMsg!, style: const TextStyle(color: Colors.white)))
          : _isReady
              ? Stack(
                  children: [
                    // Camera preview full screen
                    Positioned.fill(
                      child: _capturedFile == null
                          ? CameraPreview(_controller!)
                          : Image.file(
                              File(_capturedFile!.path),
                              fit: BoxFit.contain,
                            ),
                    ),
                    // Kotak KTP di tengah
                    if (_capturedFile == null)
                      Center(
                        child: AspectRatio(
                          aspectRatio: 85.6 / 53.98,
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _KtpGridPainter(),
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                    // Tombol kamera
                    if (!_isBusy && _capturedFile == null)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FloatingActionButton(
                            backgroundColor: Colors.white,
                            onPressed: _takePicture,
                            child: const Icon(Icons.camera_alt, color: Colors.black),
                          ),
                        ),
                      ),
                    // Tombol retake/ok
                    if (_capturedFile != null)
                      Positioned(
                        bottom: 40,
                        left: 32,
                        right: 32,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FloatingActionButton(
                              heroTag: 'retake',
                              backgroundColor: Colors.white,
                              onPressed: () => setState(() => _capturedFile = null),
                              child: const Icon(Icons.refresh, color: Colors.black),
                            ),
                            FloatingActionButton(
                              heroTag: 'ok',
                              backgroundColor: Colors.green,
                              onPressed: () => Navigator.pop(context, _capturedFile!.path),
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _KtpGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Outer KTP border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final borderRadius = 12.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, borderPaint);

    // Area NIK (sekitar 70% lebar, 15% tinggi, margin kiri 5%, atas 7%)
    final nikWidth = size.width * 0.7;
    final nikHeight = size.height * 0.15;
    final nikLeft = size.width * 0.05;
    final nikTop = size.height * 0.07;
    final nikRect = Rect.fromLTWH(nikLeft, nikTop, nikWidth, nikHeight);
    final nikPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(nikRect, nikPaint);

    // Area foto KTP (sekitar 23% lebar, 38% tinggi, margin kanan 5%, atas 18%)
    final fotoWidth = size.width * 0.23;
    final fotoHeight = size.height * 0.50;
    final fotoLeft = size.width * 0.72;
    final fotoTop = size.height * 0.18;
    final fotoRect = Rect.fromLTWH(fotoLeft, fotoTop, fotoWidth, fotoHeight);
    final fotoPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(fotoRect, fotoPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
