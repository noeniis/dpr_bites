import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_checkout.dart';
import 'package:dpr_bites/common/data/dummy_orders.dart';
import 'package:dpr_bites/features/user/pages/history/receipt_page.dart';
import 'package:dpr_bites/features/user/pages/checkout/chat_page.dart';

class CheckoutProcessPage extends StatelessWidget {
  const CheckoutProcessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final checkout = dummyCheckout;
    final items = List<Map<String, dynamic>>.from(checkout['items'] as List);
    final location = Map<String, dynamic>.from(checkout['location'] as Map);
    final restaurantName = checkout['restaurantName'] as String;

    // Proses status: 0 = konfirmasi, 1 = disiapkan, 2 = diantar (case: sudah diantar)
    final int currentStep = 2;
    final List<_StepProcess> steps = [
      _StepProcess(
        icon: 'lib/assets/images/iconCheck.png',
        label: 'Konfirmasi Resto',
        isActive: currentStep >= 0,
        isDone: currentStep > 0,
      ),
      _StepProcess(
        icon: 'lib/assets/images/spatulaknife.png',
        label: 'Makanan Lagi Disiapin',
        isActive: currentStep >= 1,
        isDone: currentStep > 1,
      ),
      _StepProcess(
        icon: 'lib/assets/images/iconDelivery.png',
        label: 'Makanan Dalam Perjalanan',
        isActive: currentStep >= 2,
        isDone: false,
      ),
    ];

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFB03056)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Proses status dan waktu
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 8,
                    bottom: 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stepper vertical
                      Column(
                        children: List.generate(steps.length * 2 - 1, (i) {
                          if (i.isEven) {
                            final step = steps[i ~/ 2];
                            final isCurrent =
                                i ~/ 2 == 2; // index 2 = proses terakhir
                            return _ProcessIcon(
                              icon: step.icon,
                              isActive: step.isActive,
                              isDone: step.isDone,
                              size: isCurrent ? 54 : 40,
                              iconSize: isCurrent ? 34 : 24,
                            );
                          } else {
                            // Garis putus-putus
                            return Container(
                              width: 2,
                              height: 32,
                              child: CustomPaint(painter: _DashedLinePainter()),
                            );
                          }
                        }),
                      ),
                      const SizedBox(width: 16),
                      // Label dan waktu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(steps.length * 2 - 1, (i) {
                            if (i.isEven) {
                              final step = steps[i ~/ 2];
                              final isGrey = step.isDone;
                              final isCurrent = i ~/ 2 == 2;
                              return SizedBox(
                                height: isCurrent ? 54 : 40,
                                // minHeight agar dua baris cukup
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    step.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isCurrent ? 14 : 13,
                                      color: isGrey
                                          ? Colors.grey
                                          : const Color(0xFF602829),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                ),
                              );
                            } else {
                              // Spacer untuk garis putus-putus
                              return const SizedBox(height: 32);
                            }
                          }),
                        ),
                      ),
                      // Waktu diantar
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 40),
                            const Text(
                              'Diantar Dalam',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color(0xFF602829),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Transform.translate(
                              offset: const Offset(-20, 0),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '15',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 48,
                                        color: Color(0xFFB03056),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' min',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                        color: Color(0xFFB03056),
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Nama resto dan chat
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          restaurantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF602829),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 43,
                        child: AspectRatio(
                          aspectRatio: 2.6,
                          child: CustomButtonKotak(
                            text: 'Chat Resto',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(restaurantName: restaurantName),
                                ),
                              );
                            },
                            backgroundColor: null, // pakai gradient default
                            textColor: Colors.white.withOpacity(0.55),
                            // Opacity gradient diatur di CustomButtonKotak
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Card info pesanan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CustomEmptyCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'lib/assets/images/iconDelivery.png',
                                width: 36,
                                height: 36,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Pesan Antar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 21,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FractionallySizedBox(
                            widthFactor: 1,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0x47000000,
                                ), // 0x47 = 28% opacity
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4E6ED),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'lib/assets/images/spatulaknife.png',
                                    width: 22,
                                    height: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Nama Restoran',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      restaurantName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4E6ED),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'lib/assets/images/iconLocation.png',
                                    width: 22,
                                    height: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alamat Antar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      location['detail'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Catatan:',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            items.any((e) => (e['note'] ?? '').isNotEmpty)
                                ? items
                                      .map((e) => e['note'])
                                      .where(
                                        (n) =>
                                            n != null &&
                                            n.toString().isNotEmpty,
                                      )
                                      .join(', ')
                                : '-',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Pesanan Kamu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CustomEmptyCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pesanan Kamu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FractionallySizedBox(
                            widthFactor: 1,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0x47000000), // 28% opacity
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...items.map(
                            (item) => Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${item['qty']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
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
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: 56,
                    child: CustomButtonKotak(
                      text: 'Detail Struk',
                      onPressed: () {
                        // Cari order yang statusnya 'berlangsung' dari dummyOrders
                        Map<String, dynamic>? ongoingOrder;
                        try {
                          ongoingOrder = dummyOrders.firstWhere(
                            (order) => order['status'] == 'berlangsung',
                          );
                        } catch (e) {
                          ongoingOrder = null;
                        }
                        if (ongoingOrder != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReceiptPage(order: ongoingOrder!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tidak ada pesanan yang sedang berlangsung.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepProcess {
  final String icon;
  final String label;
  final bool isActive;
  final bool isDone;
  _StepProcess({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDone,
  });
}

class _ProcessIcon extends StatelessWidget {
  final String icon;
  final bool isActive;
  final bool isDone;
  final double size;
  final double iconSize;
  const _ProcessIcon({
    required this.icon,
    required this.isActive,
    required this.isDone,
    this.size = 40,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isGrey = isDone;
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E6ED),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: ColorFiltered(
              colorFilter: isGrey
                  ? ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.asset(icon, width: iconSize, height: iconSize),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 2.0;
    const dashSpace = 4.0;
    double startY = 0;
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = size.width;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension _MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int, E) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}
