import 'package:flutter/material.dart';
import '../../../../../app/gradient_background.dart';
import '../../../../../common/widgets/custom_widgets.dart';

class EditMenuPage extends StatefulWidget {
  final Map<String, dynamic> menu;
  final Function(Map<String, dynamic>)? onSave;
  final Function(String)? onDelete;
  const EditMenuPage({Key? key, required this.menu, this.onSave, this.onDelete}) : super(key: key);

  @override
  State<EditMenuPage> createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  int _stock = 1;
  String _category = 'Makanan';
  bool _delivery = true;
  bool _pickup = true;
  bool _available = true;
  String _imagePath = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menu['name'] ?? '');
    _descController = TextEditingController(text: widget.menu['desc'] ?? '');
    _priceController = TextEditingController(text: widget.menu['price']?.toString() ?? '');
    _stock = widget.menu['stock'] ?? 1;
    _category = 'Makanan';
    _delivery = true;
    _pickup = true;
    _available = (widget.menu['stock'] ?? 1) > 0;
    _imagePath = widget.menu['image'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveMenu() {
    final updatedMenu = {
      ...widget.menu,
      'name': _nameController.text,
      'desc': _descController.text,
      'price': int.tryParse(_priceController.text) ?? 0,
      'stock': _stock,
      'image': _imagePath,
    };
    widget.onSave?.call(updatedMenu);
    Navigator.pop(context);
  }

  void _deleteMenu() {
    widget.onDelete?.call(widget.menu['id']);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.red),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Edit Menu', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nama menu
                  const Text('Nama menu', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  CustomInputField(
                    hintText: 'Nama menu',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),
                  // Foto hidangan
                  const Text('Foto hidangan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _imagePath,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Ukuran gambar maksimal 2 MB.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Text('Pastikan kualitas gambar jelas dan menggugah selera.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Deskripsi
                  const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  CustomInputField(
                    hintText: 'Deskripsi menu',
                    controller: _descController,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text('${_descController.text.length}/200', style: const TextStyle(fontSize: 12, color: Colors.black38)),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  // Kategori
                  const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  CustomEmptyCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(_category)),
                          Icon(Icons.chevron_right, color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Jenis layanan
                  const Text('Jenis layanan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text('Pengantaran')),
                      Checkbox(
                        value: _delivery,
                        onChanged: (val) => setState(() => _delivery = val ?? true),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Ambil di tempat')),
                      Checkbox(
                        value: _pickup,
                        onChanged: (val) => setState(() => _pickup = val ?? true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Harga
                  const Text('Harga', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  CustomInputField(
                    hintText: 'Harga',
                    controller: _priceController,
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  // Ketersediaan
                  const Text('Ketersediaan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text(_available ? 'Tersedia' : 'Tidak tersedia')),
                      Checkbox(
                        value: _available,
                        onChanged: (val) => setState(() => _available = val ?? true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Jumlah stok
                  const Text('Jumlah stok', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => setState(() { if (_stock > 0) _stock--; }),
                      ),
                      Text('$_stock', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => setState(() { _stock++; }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButtonKotak(
                          text: 'Selesai',
                          onPressed: _saveMenu,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButtonKotak(
                          text: 'Hapus menu',
                          onPressed: _deleteMenu,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
