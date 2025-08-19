import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'package:flutter/services.dart';

class KtpFormPage extends StatefulWidget {
  const KtpFormPage({super.key});

  @override
  State<KtpFormPage> createState() => _KtpFormPageState();
}

class _KtpFormPageState extends State<KtpFormPage> {
  final nameController = TextEditingController();
  final nikController = TextEditingController();
  String? gender;
  final birthPlaceController = TextEditingController();
  DateTime? birthDate;

  @override
  void dispose() {
    nameController.dispose();
    nikController.dispose();
    birthPlaceController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => birthDate = picked);
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
          title: const Text('Data KTP', style: TextStyle(color: Color(0xFF602829), fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Color(0xFF602829)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomInputField(
                  controller: nameController,
                  hintText: 'Nama Lengkap',
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomInputField(
                      controller: nikController,
                      hintText: 'NIK',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Maksimal 16 digit', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: const [
                    DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                  ],
                  onChanged: (val) => setState(() => gender = val),
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 14),
                CustomInputField(
                  controller: birthPlaceController,
                  hintText: 'Tempat Lahir',
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Lahir',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    child: Text(
                      birthDate != null
                          ? '${birthDate!.day.toString().padLeft(2, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.year}'
                          : 'Pilih tanggal',
                      style: TextStyle(
                        color: birthDate != null ? Colors.black : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonKotak(
                    text: 'Simpan dan Lanjutkan',
                    onPressed: () {
                      Navigator.pop(context, {
                        'nama': nameController.text,
                        'nik': nikController.text,
                        'gender': gender,
                        'tempat_lahir': birthPlaceController.text,
                        'tanggal_lahir': birthDate?.toIso8601String(),
                      });
                    },
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
