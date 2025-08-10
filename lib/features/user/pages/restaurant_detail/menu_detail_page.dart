import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/app/gradient_background.dart';

class MenuDetailPage extends StatefulWidget {
  final Map<String, dynamic> menu;
  final int initialQty;
  const MenuDetailPage({super.key, required this.menu, this.initialQty = 0});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  late int qty;
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    qty = widget.initialQty > 0 ? widget.initialQty : 1;
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.asset(
                                menu['image'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    menu['name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.favorite_border,
                                color: Colors.pink,
                                size: 30,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          menu['desc'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFFB0B0B0),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "${menu['price'].toString().replaceAll(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), '.')}"
                              .replaceAll('.', '.'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            hintText:
                                "Tuliskan catatan untuk restoran jika ada",
                            hintStyle: const TextStyle(
                              color: Color(0xFFB0B0B0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD53D3D),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD53D3D),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Color(0xFFD53D3D),
                                size: 32,
                              ),
                              onPressed: qty > 1
                                  ? () => setState(() => qty--)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFFD53D3D),
                                size: 32,
                              ),
                              onPressed: () => setState(() => qty++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        CustomButtonOval(
                          text: "Tambah",
                          onPressed: () {
                            Navigator.pop(context, qty);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${menu['name']} ditambahkan ke keranjang",
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> menu;
  const MenuDetailBottomSheet({super.key, required this.menu});

  @override
  State<MenuDetailBottomSheet> createState() => _MenuDetailBottomSheetState();
}

class _MenuDetailBottomSheetState extends State<MenuDetailBottomSheet> {
  int qty = 1;
  final TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    return GradientBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      menu['image'],
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        menu['name'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.pink,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(menu['desc'], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                Text(
                  "Rp ${menu['price']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    hintText: "Tuliskan catatan untuk restoran jika ada",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: qty > 1 ? () => setState(() => qty--) : null,
                    ),
                    Text(
                      '$qty',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => qty++),
                    ),
                    const Spacer(),
                    CustomButtonOval(
                      text: "Tambah",
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "✅ ${menu['name']} ditambahkan ke keranjang",
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
