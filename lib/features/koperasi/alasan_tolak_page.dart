import 'package:flutter/material.dart';
import '../../app/gradient_background.dart';
import '../../common/widgets/custom_widgets.dart';

class AlasanTolakPage extends StatefulWidget {
  final void Function(String alasan) onSubmit;
  const AlasanTolakPage({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AlasanTolakPage> createState() => _AlasanTolakPageState();
}

class _AlasanTolakPageState extends State<AlasanTolakPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> shortcutAlasan = [
    'Data kurang lengkap',
    'Foto KTP buram',
    'Data tidak valid',
    'Dokumen tidak sesuai',
  ];
  final Set<String> selectedAlasan = {};

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Alasan Penolakan'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih alasan penolakan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shortcutAlasan.map((alasan) => FilterChip(
                  label: Text(alasan),
                  selected: selectedAlasan.contains(alasan),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedAlasan.add(alasan);
                      } else {
                        selectedAlasan.remove(alasan);
                      }
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Atau tulis alasan lain:'),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan alasan penolakan',
                ),
              ),
              const Spacer(),
              CustomButtonKotak(
                text: 'Kirim',
                onPressed: () {
                  final alasanList = [
                    ...selectedAlasan,
                    if (_controller.text.trim().isNotEmpty) _controller.text.trim(),
                  ];
                  if (alasanList.isEmpty) return;
                  widget.onSubmit(alasanList.join('; '));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
