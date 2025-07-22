import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'package:dpr_bites/app/gradient_background.dart';

class MenuDetailPage extends StatefulWidget {
  final Map<String, dynamic> menu;
  const MenuDetailPage({required this.menu, super.key});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF602829)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // Gambar besar
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  menu['image'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),

              // Nama, desc, favorit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(menu['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                        if (menu['desc'] != null) Text(menu['desc'], style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text("${menu['price']}", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Color(0xFFD53D3D)),
                    onPressed: () {/* favoritkan menu */},
                  ),
                ],
              ),

              // Catatan
              const SizedBox(height: 8),
              CustomInputField(
                hintText: "Tuliskan catatan untuk restoran jika ada",
                controller: TextEditingController(),
              ),
              const SizedBox(height: 14),

              // Quantity selector & tombol tambah
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Color(0xFFD53D3D)),
                    onPressed: qty > 1 ? () => setState(() => qty--) : null,
                  ),
                  Text("$qty", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFFD53D3D)),
                    onPressed: () => setState(() => qty++),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: CustomButtonKotak(
                      text: "Tambah",
                      onPressed: () {
                        // TODO: tambah ke keranjang & back/alert
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
