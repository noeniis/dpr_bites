class DashboardRekapModel {
  final int pesananBaru;
  final int sedangDisiapkan;
  final int selfPickup;
  final int pesananAntar;
  final int totalSaldo;

  DashboardRekapModel({
    required this.pesananBaru,
    required this.sedangDisiapkan,
    required this.selfPickup,
    required this.pesananAntar,
    required this.totalSaldo,
  });

  factory DashboardRekapModel.fromJson(Map<String, dynamic> json) {
    return DashboardRekapModel(
      pesananBaru: (json['pesanan_baru'] ?? 0) as int,
      sedangDisiapkan: (json['sedang_disiapkan'] ?? 0) as int,
      selfPickup: (json['pickup'] ?? 0) as int,
      pesananAntar: (json['diantar'] ?? 0) as int,
      totalSaldo: (json['total_saldo'] ?? 0) as int,
    );
  }
}
