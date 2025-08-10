class DetailOrderModel {
  final String namaMenu;
  final int jumlah;
  final int harga;

  DetailOrderModel({
    required this.namaMenu,
    required this.jumlah,
    required this.harga,
  });

  int get totalHarga => jumlah * harga;
}

enum OrderStatus {
  cekOrder,
  sedangDisiapkan,
  pesananDiantar,
  pesananSelesai,
  orderCancel,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.cekOrder:
        return 'Cek Order';
      case OrderStatus.sedangDisiapkan:
        return 'Sedang Disiapkan';
      case OrderStatus.pesananDiantar:
        return 'Pesanan Diantar';
      case OrderStatus.pesananSelesai:
        return 'Pesanan Selesai';
      case OrderStatus.orderCancel:
        return 'Order Cancel';
    }
  }

  bool get isFinal {
    return this == OrderStatus.pesananSelesai ||
        this == OrderStatus.orderCancel;
  }
}
