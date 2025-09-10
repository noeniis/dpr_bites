class RekapPesananModel {
  final Map<String, int> statusCount;
  final int totalSaldo;
  final List<Map<String, dynamic>> menuRekap;
  final List<Map<String, dynamic>> addonRekap;

  RekapPesananModel({
    required this.statusCount,
    required this.totalSaldo,
    required this.menuRekap,
    required this.addonRekap,
  });

  factory RekapPesananModel.fromJson(Map<String, dynamic> json) {
    return RekapPesananModel(
      statusCount: Map<String, int>.from(json['debug_status_breakdown'] ?? {}),
      totalSaldo: (json['total_saldo'] ?? 0) as int,
      menuRekap: (json['menu_rekap'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      addonRekap: (json['addon_rekap'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
    );
  }
}
