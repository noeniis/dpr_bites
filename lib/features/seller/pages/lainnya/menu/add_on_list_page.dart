import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import '../../../../../app/gradient_background.dart';
import 'add_on_form_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class AddOnListPage extends StatefulWidget {
  final List<Map<String, String>>? selectedAddOns;
  const AddOnListPage({super.key, this.selectedAddOns});

  @override
  State<AddOnListPage> createState() => _AddOnListPageState();
}

class _AddOnListPageState extends State<AddOnListPage> {
  List<Map<String, String>> _addOns = [];
  final String _dummyUser = 'ikafahriza';
  bool _loading = true;
  List<int> _selectedIndexes = [];

  @override
  void initState() {
    super.initState();
    _loadAddOns();
  }

  Future<void> _loadAddOns() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'add_ons_$_dummyUser';
    final list = prefs.getStringList(key) ?? [];
    List<Map<String, String>> loadedAddOns = list.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
    // Tambah dummy jika kosong
    if (loadedAddOns.isEmpty) {
      loadedAddOns.add({
        'nama': 'Tempe',
        'deskripsi': 'Add on tempe goreng',
        'harga': '3000',
        'stok': '99',
        'foto': 'lib/assets/images/ayam_teriyaki.jpeg',
        'tersedia': 'true',
        'user': _dummyUser,
      });
    }
    List<int> selected = [];
    if (widget.selectedAddOns != null && widget.selectedAddOns!.isNotEmpty) {
      for (int i = 0; i < loadedAddOns.length; i++) {
        if (widget.selectedAddOns!.any((e) => e['nama'] == loadedAddOns[i]['nama'])) {
          selected.add(i);
        }
      }
    }
    setState(() {
      _addOns = loadedAddOns;
      _selectedIndexes = selected;
      _loading = false;
    });
  }

  Future<void> _saveAddOns() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'add_ons_$_dummyUser';
    await prefs.setStringList(key, _addOns.map((e) => jsonEncode(e)).toList());
  }

  void _addAddOn() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddOnFormPage()),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        _addOns.add(result);
      });
      _saveAddOns();
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
          title: const Text('Add On Menu', style: TextStyle(color: Color(0xFF602829), fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Color(0xFF602829)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomButtonKotak(
                      text: 'Tambah Add On',
                      onPressed: _addAddOn,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _addOns.isEmpty
                          ? const Center(child: Text('Belum ada add on yang dibuat', style: TextStyle(color: Colors.black54)))
                          : ListView.separated(
                              itemCount: _addOns.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final addOn = _addOns[i];
                                final checked = _selectedIndexes.contains(i);
                                return CustomEmptyCard(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                          leading: Padding(
                                            padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              clipBehavior: Clip.hardEdge,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: addOn['foto'] != null && addOn['foto']!.isNotEmpty
                                                  ? (addOn['foto']!.startsWith('lib/assets/')
                                                      ? Image.asset(
                                                          addOn['foto']!,
                                                          width: 48,
                                                          height: 48,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Image.file(
                                                          File(addOn['foto']!),
                                                          width: 48,
                                                          height: 48,
                                                          fit: BoxFit.cover,
                                                        ))
                                                  : const Icon(Icons.fastfood, color: Colors.orange, size: 32),
                                            ),
                                          ),
                                          title: Text(addOn['nama'] ?? '-'),
                                          subtitle: Text('Stok: ${addOn['stok'] ?? '-'} | Harga: Rp${addOn['harga'] ?? '-'}'),
                                          trailing: addOn['tersedia'] == 'true'
                                              ? const Icon(Icons.check_circle, color: Colors.green)
                                              : const Icon(Icons.cancel, color: Colors.red),
                                        ),
                                      ),
                                      Checkbox(
                                        value: checked,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIndexes.add(i);
                                            } else {
                                              _selectedIndexes.remove(i);
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    CustomButtonKotak(
                      text: 'Simpan Pilihan',
                      onPressed: () {
                        final selected = _selectedIndexes.map((i) => _addOns[i]).toList();
                        Navigator.pop(context, selected);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
