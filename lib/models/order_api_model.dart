class OrderApiModel {
  final String idTransaksi;
  final String bookingId;
  final String status;
  final String idUsers;
  final String namaPemesan;
  final String metodePembayaran;
  final String? buktiPembayaran;

  OrderApiModel({
    required this.idTransaksi,
    required this.bookingId,
    required this.status,
    required this.idUsers,
    required this.namaPemesan,
    required this.metodePembayaran,
    this.buktiPembayaran,
  });

  factory OrderApiModel.fromJson(Map<String, dynamic> json) {
    return OrderApiModel(
      idTransaksi: json['id_transaksi']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      idUsers: json['id_users']?.toString() ?? '',
      namaPemesan: json['nama_lengkap']?.toString() ?? '',
      metodePembayaran: json['metode_pembayaran']?.toString() ?? '',
      buktiPembayaran: json['bukti_pembayaran']?.toString(),
    );
  }
}
