import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final Map<String, dynamic> menu;
  final VoidCallback? onTap;
  const MenuCard({required this.menu, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,   // <--- Set fixed width
        height: 170,  // <--- Set fixed height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                menu['image'],
                width: 120,   // <--- Match width
                height: 70,   // <--- Image height
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menu['price'].toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.favorite_border, color: Color(0xFFD53D3D), size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
