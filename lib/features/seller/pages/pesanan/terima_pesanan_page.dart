import 'package:flutter/material.dart';
import 'package:dpr_bites/models/order_model.dart';
import 'package:dpr_bites/models/detail_order_model.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';

class TerimaPesananPage extends StatelessWidget {
  final OrderModel order;

  const TerimaPesananPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Dummy detail pesanan (bisa dipindah ke file data kalau dibutuhkan)
    final List<DetailOrderModel> detailItems = [
      DetailOrderModel(namaMenu: 'Nasi Pecel', jumlah: 1, harga: 20000),
      DetailOrderModel(namaMenu: 'Paket Ayam Bakar', jumlah: 2, harga: 25000),
    ];

    int totalHarga = detailItems.fold(
      0,
      (sum, item) => sum + (item.jumlah * item.harga),
    );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFD53D3D), size: 28),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Pesanan Masuk',
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomEmptyCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.jumlahPesanan} Pesanan untuk ${order.namaPemesan}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF602829),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booking ID: ${order.bookingId}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF50555C),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Pesan Antar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF602829),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.location_on, size: 20, color: Colors.black),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Pustekinfo, Lt 2 Gedung Nusantara I',
                                style: TextStyle(fontSize: 14, color: Color(0xFF50555C)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...detailItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ' ${item.jumlah} ×  ${item.namaMenu}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF602829),
                                  ),
                                ),
                                Text(
                                  'Rp ${(item.harga * item.jumlah).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xB51E1E1E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Harga Total',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF602829)),
                            ),
                            Text(
                              'Rp $totalHarga',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD53D3D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CustomButtonKotak(
                          text: 'Terima Pesanan',
                          onPressed: () {
                            Navigator.pop(context, 'accepted');
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButtonKotak(
                          text: 'Batalkan Pesanan',
                          backgroundColor: const Color(0xFF9E9595),
                          onPressed: () {
                            Navigator.pop(context, 'canceled');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
