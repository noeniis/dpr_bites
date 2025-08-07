import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class PilihEtalasePage extends StatefulWidget {
  final List<String> etalaseList;
  final List<String> selectedEtalase;
  const PilihEtalasePage({super.key, required this.etalaseList, required this.selectedEtalase});

  @override
  State<PilihEtalasePage> createState() => _PilihEtalasePageState();
}

class _PilihEtalasePageState extends State<PilihEtalasePage> {
  late List<String> _selected;
  List<String> _etalase = [];
  final TextEditingController _newEtalaseController = TextEditingController();
  final String _dummyUser = 'ikafahriza';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedEtalase);
    _loadEtalase();
  }

  Future<void> _loadEtalase() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'etalase_${_dummyUser}';
    final list = prefs.getStringList(key) ?? [];
    setState(() {
      _etalase = list;
      _loading = false;
    });
  }

  Future<void> _saveEtalase() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'etalase_${_dummyUser}';
    await prefs.setStringList(key, _etalase);
  }

  void _addEtalase() {
    final name = _newEtalaseController.text.trim();
    if (name.isNotEmpty && !_etalase.contains(name)) {
      setState(() {
        _etalase.add(name);
        _selected.add(name);
        _newEtalaseController.clear();
      });
      _saveEtalase();
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
          title: const Text('Pilih/Tambah Etalase', style: TextStyle(color: Color(0xFF602829), fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Color(0xFF602829)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomEmptyCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Etalase membantu mengelompokkan paket atau jenis makanan/minuman yang dijual. Tambahkan etalase sesuai kebutuhan tokomu.',
                                style: TextStyle(fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Tambah etalase baru:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newEtalaseController,
                            decoration: const InputDecoration(hintText: 'Nama etalase baru'),
                          ),
                        ),
                        CustomButtonKotak(
                          text: 'Tambah',
                          onPressed: _addEtalase,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Etalase yang sudah dibuat:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _etalase.isEmpty
                          ? Center(
                              child: Text('Belum ada etalase yang dibuat', style: TextStyle(color: Colors.black54)),
                            )
                          : ListView(
                              children: _etalase.map((e) => CustomEmptyCard(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: CheckboxListTile(
                                  value: _selected.contains(e),
                                  title: Text(e),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selected.add(e);
                                      } else {
                                        _selected.remove(e);
                                      }
                                    });
                                  },
                                ),
                              )).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    CustomButtonKotak(
                      text: 'Simpan',
                      onPressed: () {
                        Navigator.pop(context, _selected);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
