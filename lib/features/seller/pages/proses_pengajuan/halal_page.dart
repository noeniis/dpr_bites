import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'informasi_rekening_page.dart';

class HalalPage extends StatefulWidget {
  final Map<String, dynamic> storeData;
  const HalalPage({Key? key, required this.storeData}) : super(key: key);

  @override
  State<HalalPage> createState() => _HalalPageState();
}

class _HalalPageState extends State<HalalPage> {
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    // Set default or restore value if exists
    if (widget.storeData['halal'] == null) {
      _selectedOption = '1';
    } else {
      _selectedOption = widget.storeData['halal'];
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
              // Kembalikan data ke page sebelumnya
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
                  value: '1',
                  groupValue: _selectedOption,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                      widget.storeData['halal'] = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text(
                    "Tidak, kami tidak memiliki sertifikat halal",
                  ),
                  value: '0',
                  groupValue: _selectedOption,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                      widget.storeData['halal'] = value;
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
                      onPressed: () {
                        // Simpan hanya field halal sebagai string '1'/'0'
                        widget.storeData['halal'] = _selectedOption;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InformasiRekeningPage(storeData: widget.storeData),
                          ),
                        );
                      },
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
