import 'package:flutter/material.dart';
import 'package:dpr_bites/models/order_model.dart';
import 'pesanan_selesai_page.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';

class SiapDiantarPage extends StatelessWidget {
  final OrderModel order;

  const SiapDiantarPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFD53D3D), size: 28),
            onPressed: () => Navigator.pop(context),
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
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomEmptyCard(
                  margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${order.jumlahPesanan} Pesanan untuk ${order.namaPemesan}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF602829),
                                ),
                              ),
                            ),
                            Text(
                              'Booking ID: ${order.bookingId}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF50555C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pesan Antar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF602829),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.location_on, size: 18, color: Color(0xFF1E7A1E)),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Pustekinfo, Lt 2 Gedung Nusantara I',
                                style: TextStyle(fontSize: 13, color: Color(0xFF50555C)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('1 ×', style: TextStyle(fontSize: 15, color: Colors.black)),
                            const SizedBox(width: 4),
                            const Text('Nasi Pecel', style: TextStyle(fontSize: 15, color: Colors.black)),
                            const Spacer(),
                            const Text('Rp 20.000', style: TextStyle(fontSize: 15, color: Colors.black)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('2 ×', style: TextStyle(fontSize: 15, color: Colors.black)),
                            const SizedBox(width: 4),
                            const Text('Paket Ayam Bakar', style: TextStyle(fontSize: 15, color: Colors.black)),
                            const Spacer(),
                            const Text('Rp 50.000', style: TextStyle(fontSize: 15, color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Harga Total', style: TextStyle(fontSize: 15, color: Colors.black)),
                            Text('Rp 70.000', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomButtonKotak(
                    text: 'Pesanan siap diantar',
                    onPressed: () {
                      // Update status pesanan dan kembali ke PesananPage
                      order.status = 'pesanan diantar';
                      Navigator.pop(context, 'delivered');
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
