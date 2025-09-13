class ReviewModel {
  final int idTransaksi;
  final int rating; // 1..5
  final String komentar; // optional text (could be empty)
  final bool anonymous; // true if anonymous

  ReviewModel({
    required this.idTransaksi,
    required this.rating,
    required this.komentar,
    required this.anonymous,
  });

  Map<String, dynamic> toJson() => {
    'id_transaksi': idTransaksi,
    'rating': rating,
    'komentar': komentar,
    'anonymous': anonymous ? 1 : 0,
  };
}

class ReviewSubmitResult {
  final bool success;
  final String? message;
  ReviewSubmitResult({required this.success, this.message});
}
