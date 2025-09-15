import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'informasi_rekening_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/halal_status_service.dart';

class HalalPage extends StatefulWidget {
  const HalalPage({super.key});

  @override
  State<HalalPage> createState() => _HalalPageState();
}

class _HalalPageState extends State<HalalPage> {
  final _storage = FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    _loadHalalStatus();
  }

  Future<void> _loadHalalStatus() async {
    final idUsers = await _storage.read(key: 'id_users') ?? '';
    if (idUsers.isEmpty) return;
    final status = await HalalStatusService.getHalalStatus(idUsers);
    setState(() {
      _selectedOption = status;
    });
  }
  Future<void> _saveHalalStatus() async {
    final idUsers = await _storage.read(key: 'id_users') ?? '';
    final success = await HalalStatusService.saveHalalStatus(idUsers, _selectedOption);
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InformasiRekeningPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan status halal, coba lagi')),
      );
    }
  }
  String? _selectedOption;

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
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Lengkapi informasi jenis masakan",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Bantu pelanggan membuat pilihan yang tepat dengan memberikan informasi mengenai jenis masakan dan status kehalalan makanan.",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Jenis masakan dan sertifikasi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Apakah gerai ini memiliki sertifikasi Halal?",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text("Ya, kami memiliki sertifikat halal"),
                  value: 'ya',
                  groupValue: _selectedOption,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text(
                    "Tidak, kami tidak memiliki sertifikat halal",
                  ),
                  value: 'tidak',
                  groupValue: _selectedOption,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                    });
                  },
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButtonKotak(
                      text: "Simpan dan lanjutkan",
                      onPressed: _saveHalalStatus,
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
