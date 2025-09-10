import 'package:dpr_bites/features/seller/models/addon_model.dart';
import 'package:dpr_bites/features/seller/services/addon_service.dart';
import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import '../../../../../app/gradient_background.dart';
import 'add_on_form_page.dart';


class AddOnListPage extends StatefulWidget {
  final List<AddonModel>? selectedAddOns;
  const AddOnListPage({super.key, this.selectedAddOns});

  @override
  State<AddOnListPage> createState() => _AddOnListPageState();
}

class _AddOnListPageState extends State<AddOnListPage> {
  List<AddonModel> _addOns = [];
  bool _loading = true;
  List<int> _selectedIndexes = [];
  @override
  void initState() {
    super.initState();
    _loadUserAndGeraiAndAddOns();
  }

  Future<void> _loadUserAndGeraiAndAddOns() async {
    final addOnList = await AddonService.fetchAddonsByGeraiFromPrefs();
    List<int> selected = [];
    if (widget.selectedAddOns != null && widget.selectedAddOns!.isNotEmpty) {
      for (int i = 0; i < addOnList.length; i++) {
        if (widget.selectedAddOns!.any((e) => e.namaAddon == addOnList[i].namaAddon)) {
          selected.add(i);
        }
      }
    }
    setState(() {
      _addOns = addOnList;
      _selectedIndexes = selected;
      _loading = false;
    });
  }

  void _addAddOn() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddOnFormPage()),
    );
    if (result != null) {
      // Reload dari API setelah tambah
      setState(() {
        _loading = true;
      });
      await _loadUserAndGeraiAndAddOns();
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
          title: const Text('Add On Menu', style: TextStyle(color: Color(0xFF602829), fontSize: 20)),
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
                                              child: addOn.imagePath.isNotEmpty
                                                  ? (addOn.imagePath.startsWith('http')
                                                      ? Image.network(addOn.imagePath, fit: BoxFit.cover)
                                                      : Image.asset('lib/assets/images/chalkboard_menu.jpeg', fit: BoxFit.cover))
                                                  : const Icon(Icons.fastfood, color: Colors.orange, size: 32),
                                            ),
                                          ),
                      title: Text(addOn.namaAddon),
                      subtitle: Text('Harga: Rp${addOn.harga}'),
                      trailing: addOn.tersedia
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
                  ],
                ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16), 
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonKotak(
                    text: 'Simpan',
                    onPressed: () {
                      final selected = _selectedIndexes.map((i) => _addOns[i]).toList();
                      Navigator.pop(context, selected);
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
