import 'package:dpr_bites/features/seller/services/etalase_service.dart';
import 'package:flutter/material.dart';
import '../../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/features/seller/models/etalase_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PilihEtalasePage extends StatefulWidget {
  final List<EtalaseModel> selectedEtalase;
  const PilihEtalasePage({
    super.key,
  required this.selectedEtalase,
  });

  @override
  State<PilihEtalasePage> createState() => _PilihEtalasePageState();
}

class _PilihEtalasePageState extends State<PilihEtalasePage> {
  late List<EtalaseModel> _selected;
  List<EtalaseModel> _etalase = [];
  final TextEditingController _newEtalaseController = TextEditingController();
  String? _idGerai;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
  _selected = List<EtalaseModel>.from(widget.selectedEtalase);
    _loadUserAndGeraiAndEtalase();
  }

  void _addEtalase() async {
    final name = _newEtalaseController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama etalase tidak boleh kosong!')),
      );
      return;
    }
    if (_idGerai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Gerai tidak ditemukan!')),
      );
      return;
    }
    if (_etalase.any((e) => e.namaEtalase == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama etalase sudah ada!')),
      );
      return;
    }
    setState(() { _loading = true; });
    final success = await EtalaseService.addEtalase(
      idGerai: int.parse(_idGerai!),
      namaEtalase: name,
    );
    if (success) {
      _newEtalaseController.clear();
      await _loadUserAndGeraiAndEtalase();
    } else {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal tambah etalase')),);
    }
  }

  Future<void> _loadUserAndGeraiAndEtalase() async {
    setState(() { _loading = true; });
    final storage = FlutterSecureStorage();
    _idGerai = await storage.read(key: 'id_gerai');
    if (_idGerai != null) {
      final etalaseList = await EtalaseService.fetchEtalase(idGerai: int.parse(_idGerai!));
      setState(() {
        _etalase = etalaseList;
        _loading = false;
      });
    } else {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Gerai tidak ditemukan!')),
      );
    }
  }

  void _deleteEtalase(EtalaseModel etalase) async {
    final id = etalase.idEtalase;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Etalase'),
        content: Text('Yakin ingin menghapus etalase "${etalase.namaEtalase}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() { _loading = true; });
    final success = await EtalaseService.deleteEtalase(idEtalase: id);
    if (success) {
      _selected.removeWhere((e) => e.idEtalase == id);
      await _loadUserAndGeraiAndEtalase();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etalase berhasil dihapus.')));
    } else {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal hapus etalase')),);
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
          title: const Text('Pilih/Tambah Etalase',
              style: TextStyle(fontSize: 20, color: Color(0xFF602829))),
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
                            Text(
                              'Etalase membantu mengelompokkan paket atau jenis makanan/minuman yang dijual. Tambahkan etalase sesuai kebutuhan tokomu.',
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Tambah etalase baru:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newEtalaseController,
                            decoration:
                                const InputDecoration(hintText: 'Nama etalase baru'),
                          ),
                        ),
                        CustomButtonKotak(
                          text: 'Tambah',
                          onPressed: _addEtalase,
                          fontSize: 14,
                          width: 80,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Etalase yang sudah dibuat:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _etalase.isEmpty
                          ? const Center(
                              child: Text('Belum ada etalase yang dibuat',
                                  style: TextStyle(color: Colors.black54)),
                            )
                          : ListView.builder(
                              itemCount: _etalase.length,
                              itemBuilder: (context, idx) {
                                final e = _etalase[idx];
                                final isSelected = _selected.isNotEmpty && _selected.first.idEtalase == e.idEtalase;
                                return CustomEmptyCard(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<int>(
                                          value: e.idEtalase,
                                          groupValue: isSelected ? e.idEtalase : (_selected.isNotEmpty ? _selected.first.idEtalase : null),
                                          title: Text(e.namaEtalase),
                                          onChanged: (val) {
                                            setState(() {
                                              _selected.clear();
                                              _selected.add(e);
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Hapus etalase',
                                        onPressed: () => _deleteEtalase(e),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonKotak(
                    text: 'Simpan',
                    onPressed: () {
                      Navigator.pop(context, _selected);
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
