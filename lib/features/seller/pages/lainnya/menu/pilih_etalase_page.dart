import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  List<Map<String, dynamic>> _etalase = [];
  final TextEditingController _newEtalaseController = TextEditingController();
  String? _idUser;
  String? _idGerai;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
  _selected = List<String>.from(widget.selectedEtalase);
  _loadUserAndGeraiAndEtalase();
  }

  // Method lama dihapus, sudah diganti dengan API

  void _addEtalase() {
    final name = _newEtalaseController.text.trim();
    if (name.isEmpty || _idGerai == null) return;
    // cek duplikat
    if (_etalase.any((e) => e['nama_etalase'] == name)) return;
    setState(() { _loading = true; });
    // panggil API tambah etalase
    http.post(
      Uri.parse('http://10.0.2.2/dpr_bites_api/add_etalase.php'),
      body: {
        'id_gerai': _idGerai!,
        'nama_etalase': name,
      },
    ).then((response) {
      final resJson = jsonDecode(response.body);
      if (resJson['success'] == true) {
        _newEtalaseController.clear();
        _loadUserAndGeraiAndEtalase();
        setState(() {
          _selected.add(name);
        });
      } else {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal tambah etalase: ${resJson['error'] ?? 'Unknown error'}')),
        );
      }
    });
  }

  Future<void> _loadUserAndGeraiAndEtalase() async {
    setState(() { _loading = true; });
    final prefs = await SharedPreferences.getInstance();
    _idUser = prefs.getString('id_users');
    if (_idUser != null) {
      final responseGerai = await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/get_gerai_by_user.php'),
        body: {'id_users': _idUser},
      );
      final dataGerai = jsonDecode(responseGerai.body);
      if (dataGerai['success'] == true && dataGerai['id_gerai'] != null) {
        _idGerai = dataGerai['id_gerai'].toString();
        final responseEtalase = await http.get(
          Uri.parse('http://10.0.2.2/dpr_bites_api/get_etalase.php?id_gerai=$_idGerai'),
        );
        final dataEtalase = jsonDecode(responseEtalase.body);
        List<Map<String, dynamic>> loadedEtalase = [];
        if (dataEtalase['success'] == true && dataEtalase['etalase'] != null) {
          loadedEtalase = List<Map<String, dynamic>>.from(dataEtalase['etalase']);
        }
        setState(() {
          _etalase = loadedEtalase;
          _loading = false;
        });
      } else {
        setState(() { _loading = false; });
      }
    } else {
      setState(() { _loading = false; });
    }
  // kurung tutup berlebih dihapus
  }

  void _deleteEtalase(Map<String, dynamic> etalase) async {
    final id = etalase['id_etalase']?.toString();
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Etalase'),
        content: Text('Yakin ingin menghapus etalase "${etalase['nama_etalase']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() { _loading = true; });
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/delete_etalase.php'),
        body: {'id_etalase': id},
      );
      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true) {
          _selected.remove(etalase['nama_etalase']);
          await _loadUserAndGeraiAndEtalase();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etalase berhasil dihapus.')));
        } else {
          setState(() { _loading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal hapus etalase: ${resJson['message'] ?? 'Unknown error'}')),
          );
        }
      } else {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus etalase: HTTP ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus etalase: ${e.toString()}')),
      );
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
          title: const Text('Pilih/Tambah Etalase', style: TextStyle(fontSize: 20, color: Color(0xFF602829))),
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
                          fontSize: 14,
                          width: 80,
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
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CheckboxListTile(
                                        value: _selected.contains(e['nama_etalase']),
                                        title: Text(e['nama_etalase'] ?? '-'),
                                        controlAffinity: ListTileControlAffinity.leading,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selected.add(e['nama_etalase']);
                                            } else {
                                              _selected.remove(e['nama_etalase']);
                                            }
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
                              )).toList(),
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
                SizedBox(height: 16), // Jeda atas
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
