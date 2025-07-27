import 'package:flutter/material.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'checkout_process_page.dart';

class PembayaranQrisDialog extends StatelessWidget {
  final VoidCallback onKonfirmasi;
  final VoidCallback onBatal;
  const PembayaranQrisDialog({
    Key? key,
    required this.onKonfirmasi,
    required this.onBatal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: onBatal,
                  tooltip: 'Batal',
                ),
              ],
            ),
            const Text(
              'QRIS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'lib/assets/images/iconQR.png',
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            CustomButtonOval(
              text: 'Konfirmasi',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CheckoutProcessPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
