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

    int ongkir = 5000;
    int subtotal = detailItems.fold(
      0,
      (sum, item) => sum + (item.jumlah * item.harga),
    );
    int totalHarga = subtotal + ongkir;

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
                        // Header row detail
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Expanded(child: Text('Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                              SizedBox(width: 12),
                              Text('Harga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(width: 12),
                              Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                        const Divider(height: 18),
                        ...detailItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.jumlah} × ${item.namaMenu}',
                                    style: const TextStyle(fontSize: 16, color: Color(0xFF602829)),
                                  ),
                                ),
                                SizedBox(width: 12),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'Rp ${item.harga}',
                                    style: const TextStyle(fontSize: 16, color: Color(0xB51E1E1E)),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(width: 12),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    'Rp ${(item.harga * item.jumlah)}',
                                    style: const TextStyle(fontSize: 16, color: Color(0xB51E1E1E)),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Ongkir row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Ongkir', style: TextStyle(fontSize: 15, color: Color(0xFF602829))),
                            Text('Rp 5000', style: TextStyle(fontSize: 15, color: Color(0xFF602829))),
                          ],
                        ),
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
                          onPressed: () async {
                            String? alasan = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                String? selectedReason;
                                TextEditingController alasanController = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Alasan Pembatalan'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedReason,
                                        hint: const Text('Pilih alasan'),
                                        items: const [
                                          DropdownMenuItem(value: 'Stok kosong', child: Text('Stok kosong')),
                                          DropdownMenuItem(value: 'Menu habis', child: Text('Menu habis')),
                                          DropdownMenuItem(value: 'Toko tutup', child: Text('Toko tutup')),
                                          DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                                        ],
                                        onChanged: (val) {
                                          selectedReason = val;
                                          if (val != 'Lainnya') {
                                            alasanController.text = val ?? '';
                                          } else {
                                            alasanController.text = '';
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: alasanController,
                                        enabled: selectedReason == 'Lainnya',
                                        decoration: const InputDecoration(
                                          hintText: 'Isi alasan lain (opsional)',
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if ((selectedReason != null && selectedReason!.isNotEmpty) || alasanController.text.isNotEmpty) {
                                          Navigator.pop(context, alasanController.text.isNotEmpty ? alasanController.text : selectedReason);
                                        }
                                      },
                                      child: const Text('Kirim'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (alasan != null && alasan.isNotEmpty) {
                              Navigator.pop(context, {'status': 'canceled', 'alasan': alasan});
                            }
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
