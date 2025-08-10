import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_orders.dart';
import 'package:dpr_bites/features/user/pages/checkout/checkout_process_page.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic> order;
  const ReceiptPage({super.key, required this.order});

  void copyBookingId(BuildContext context, String bookingId) {
    Clipboard.setData(ClipboardData(text: bookingId));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Booking ID berhasil disalin')));
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = order['id'] ?? '-';
    final restaurantName = order['restaurantName'] ?? '-';
    final status = order['status'] ?? '-';
    final iconPath = order['icon'] ?? 'lib/assets/images/spatulaknife.png';
    final locationSeller = order['locationSeller'] ?? '-';
    final locationBuyer = order['locationBuyer'] ?? '-';
    final orderSummary = order['orderSummary'] as List<dynamic>? ?? [];
    final subtotal = orderSummary.fold<int>(
      0,
      (sum, item) => sum + ((item['price'] ?? 0) as int),
    );
    final deliveryFee = order['delivery'] == true
        ? (order['deliveryFee'] ?? 0)
        : 0;
    final total = subtotal + deliveryFee;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
          title: const Text(
            'Struk Pemesanan',
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Booking ID',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              bookingId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                color: Color(0xFFB03056),
                                size: 20,
                              ),
                              onPressed: () =>
                                  copyBookingId(context, bookingId),
                              tooltip: 'Copy',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4E6ED),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              red: 0.08,
                              green: 0.08,
                              blue: 0.08,
                              alpha: 1,
                            ),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(iconPath, width: 30, height: 30),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          restaurantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 15,
                            color: status == 'selesai'
                                ? Colors.green
                                : status == 'berlangsung'
                                ? Colors.orange
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column for icons and dashed line
                      Column(
                        children: [
                          // Seller icon (no background, bigger)
                          Image.asset(
                            'lib/assets/images/iconCircle.png',
                            width: 28,
                            height: 28,
                          ),
                          SizedBox(height: 6),
                          // Shorter vertical dashed line, centered
                          Column(
                            children: List.generate(
                              3,
                              (i) => Container(
                                width: 2,
                                height: 6,
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 142, 142, 142),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          // Buyer icon (iconLocation, bigger)
                          Image.asset(
                            'lib/assets/images/iconLocation.png',
                            width: 28,
                            height: 28,
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Column for addresses
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 0),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                locationSeller,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                locationBuyer,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD9D9D9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Rangkuman Pemesanan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const Divider(
                        thickness: 2.5,
                        color: Color(0xFFB03056),
                        height: 0,
                      ),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                        },
                        border: TableBorder.all(
                          style: BorderStyle.none,
                          color: Colors.transparent,
                        ),
                        children: [
                          ...orderSummary.asMap().entries.map((entry) {
                            final item = entry.value;
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '${item['qty']}x  ${item['menu']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Rp${item['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      if (orderSummary.isNotEmpty)
                        const Divider(
                          thickness: 1,
                          color: Color(0xFFD9D9D9),
                          height: 0,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Rp${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (deliveryFee > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ongkos Kirim',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Rp${deliveryFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(
                        thickness: 1,
                        color: Color(0xFFD9D9D9),
                        height: 0,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Rp${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (status == 'berlangsung') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: CustomButtonKotak(
                      text: 'Lihat Proses Pesanan',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CheckoutProcessPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: CustomButtonKotak(
                    text: 'Hubungi Kami',
                    onPressed: () {
                      // Aksi button, tidak ada link
                    },
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
