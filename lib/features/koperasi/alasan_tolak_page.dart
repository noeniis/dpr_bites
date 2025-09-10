import 'package:flutter/material.dart';
import '../../app/gradient_background.dart';
import '../../common/widgets/custom_widgets.dart';
import 'models/alasan_tolak_model.dart';

class AlasanTolakPage extends StatefulWidget {
  final void Function(String alasan) onSubmit;
  const AlasanTolakPage({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AlasanTolakPage> createState() => _AlasanTolakPageState();
}

class _AlasanTolakPageState extends State<AlasanTolakPage> {
  final TextEditingController _controller = TextEditingController();
  final AlasanTolakModel alasanModel = AlasanTolakModel();

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
                children: alasanModel.shortcutAlasan.map((alasan) => FilterChip(
                  label: Text(alasan),
                  selected: alasanModel.selectedAlasan.contains(alasan),
                  onSelected: (selected) {
                    setState(() {
                      alasanModel.toggleAlasan(alasan, selected);
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
                onChanged: (val) {
                  alasanModel.alasanLain = val;
                },
              ),
              const Spacer(),
              CustomButtonKotak(
                text: 'Kirim',
                onPressed: () {
                  final alasanGabung = alasanModel.alasanGabung;
                  if (alasanGabung.isEmpty) return;
                  widget.onSubmit(alasanGabung);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
