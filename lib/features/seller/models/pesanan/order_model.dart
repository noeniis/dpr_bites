class OrderModel {
  final String namaPemesan;
  final String bookingId;
  final int jumlahPesanan;
  String status; 
  String? keterangan;

  OrderModel({
    required this.namaPemesan,
    required this.bookingId,
    required this.jumlahPesanan,
    this.status = 'pending',
    this.keterangan,
  });
}
