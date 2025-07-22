import 'package:flutter/material.dart';

class MenuCardVertikal extends StatelessWidget {
  final Map<String, dynamic> menu;
  final VoidCallback? onTapAdd;
  const MenuCardVertikal({
    required this.menu,
    this.onTapAdd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Menu
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                menu['image'],
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            // Nama & Harga
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${menu['price']}".replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
                      (Match m) => '${m[1]}.'
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            // Button tambah/aksi
            InkWell(
              onTap: onTapAdd,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD53D3D), width: 1.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Color(0xFFD53D3D), size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
