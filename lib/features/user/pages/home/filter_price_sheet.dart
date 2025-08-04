import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<String> priceRanges = [];

  @override
  void initState() {
    super.initState();
    selectedRange = widget.initialValue;
    fetchPriceRanges();
  }

  Future<void> fetchPriceRanges() async {
    List<String> ranges = [
      '<10.000',
      '10.000 – 20.000',
      '20.001 – 30.000',
      '>30.000',
    ];
    setState(() {
      priceRanges = ranges;
    });
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
          ...(priceRanges.isNotEmpty ? priceRanges : ['Tidak ada data harga'])
              .map(
                (label) => RadioListTile<String>(
                  value: label,
                  groupValue: selectedRange,
                  onChanged: (v) => setState(() => selectedRange = v),
                  title: Text(label),
                  activeColor: const Color(0xFFD53D3D),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CustomButtonKotak(
                  text: "Hapus Filter",
                  onPressed: () => Navigator.pop(context, null),
                ),
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
