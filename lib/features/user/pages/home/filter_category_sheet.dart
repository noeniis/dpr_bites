import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';

class FilterCategorySheet extends StatefulWidget {
  final String? initialValue;
  const FilterCategorySheet({this.initialValue, super.key});
  @override
  State<FilterCategorySheet> createState() => _FilterCategorySheetState();
}

class _FilterCategorySheetState extends State<FilterCategorySheet> {
  String? selectedCat;
  void initState() {
    super.initState();
    selectedCat = widget.initialValue; // <-- set defaultnya dari atas!
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Kategori Kuliner",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 20),
          ...['Makanan', 'Minuman', 'Jajanan'].map((label) => RadioListTile<String>(
                value: label,
                groupValue: selectedCat,
                onChanged: (v) => setState(() => selectedCat = v),
                title: Text(label),
                activeColor: const Color(0xFFD53D3D),
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CustomButtonKotak(
                text: "Hapus Filter",
                onPressed: () => Navigator.pop(context, null),
              )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButtonKotak(
                  text: "Terapkan",
                  onPressed: () => Navigator.pop(context, selectedCat),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
