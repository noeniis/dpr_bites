import 'package:flutter/material.dart';
import '../../../../common/data/dummy_carts.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../checkout/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> carts = List<Map<String, dynamic>>.from(
    dummyCarts,
  );
  bool isEditMode = false;
  Set<int> selectedIndexes = {};
  bool get isAllSelected =>
      selectedIndexes.length == carts.length && carts.isNotEmpty;

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
      if (!isEditMode) selectedIndexes.clear();
    });
  }

  void toggleSelect(int idx) {
    setState(() {
      if (selectedIndexes.contains(idx)) {
        selectedIndexes.remove(idx);
      } else {
        selectedIndexes.add(idx);
      }
    });
  }

  void selectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedIndexes = Set.from(List.generate(carts.length, (i) => i));
      } else {
        selectedIndexes.clear();
      }
    });
  }

  void deleteSelected() {
    setState(() {
      carts = List<Map<String, dynamic>>.from(
        carts
            .asMap()
            .entries
            .where((entry) => !selectedIndexes.contains(entry.key))
            .map((e) => e.value),
      );
      selectedIndexes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9D3D3), Colors.white],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF602829)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Keranjang',
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            TextButton(
              onPressed: toggleEditMode,
              child: Text(
                isEditMode ? 'Batal' : 'Atur',
                style: const TextStyle(
                  color: Color(0xFF602829),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: carts.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Colors.black12),
                itemBuilder: (context, idx) {
                  final cart = carts[idx];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 0,
                    ),
                    leading: isEditMode
                        ? Checkbox(
                            value: selectedIndexes.contains(idx),
                            onChanged: (_) => toggleSelect(idx),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            activeColor: const Color(0xFFD53D3D),
                          )
                        : null,
                    title: Text(
                      cart['restaurantName'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF602829),
                      ),
                    ),
                    subtitle: Text(
                      '${cart['itemCount']} Item - Estimasi ${cart['estimate']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        cart['image'] as String,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                    ),
                    onTap: isEditMode
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutPage(),
                              ),
                            );
                          },
                  );
                },
              ),
            ),
            if (isEditMode)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, -1),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      onChanged: selectAll,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: const Color(0xFFD53D3D),
                    ),
                    const Text(
                      'Pilih Semua',
                      style: TextStyle(fontSize: 15, color: Color(0xFF602829)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 140,
                      child: CustomButtonKotak(
                        text: 'Hapus',
                        onPressed: selectedIndexes.isEmpty ? null : deleteSelected,
                      ),
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
