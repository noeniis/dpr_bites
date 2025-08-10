class OrderModel {
  final String namaPemesan;
  final String bookingId;
  final int jumlahPesanan;
  String status; // 'pending' atau 'sedang disiapkan'
  String? keterangan;

  OrderModel({
    required this.namaPemesan,
    required this.bookingId,
    required this.jumlahPesanan,
    this.status = 'pending',
    this.keterangan,
  });
}
