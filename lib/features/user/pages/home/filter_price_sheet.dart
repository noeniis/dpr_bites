import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';

class FilterPriceSheet extends StatefulWidget {
  final String? initialValue;
  const FilterPriceSheet({this.initialValue, super.key});
  @override
  State<FilterPriceSheet> createState() => _FilterPriceSheetState();

}

class _FilterPriceSheetState extends State<FilterPriceSheet> {
  String? selectedRange;
  void initState() {
    super.initState();
    selectedRange = widget.initialValue; // <-- set defaultnya dari atas!
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Pilih Rentang Harga",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 20),
          ...[
            '<15.000',
            '15.000 – 25.000',
            '15.000 – 35.000',
            '>35.000',
          ].map((label) => RadioListTile<String>(
                value: label,
                groupValue: selectedRange,
                onChanged: (v) => setState(() => selectedRange = v),
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
                  onPressed: () => Navigator.pop(context, selectedRange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
