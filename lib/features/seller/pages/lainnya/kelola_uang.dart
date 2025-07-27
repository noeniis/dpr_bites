import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class KelolaUangPage extends StatefulWidget {
  const KelolaUangPage({Key? key}) : super(key: key);

  @override
  State<KelolaUangPage> createState() => _KelolaUangPageState();
}

class _KelolaUangPageState extends State<KelolaUangPage> {
  double saldo = 50000;

  void _showTarikSaldoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Konfirmasi Tarik Saldo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Apakah Anda yakin ingin menarik saldo?'),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            saldo = 0;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Ya'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.red),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Kelola Keuangan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomSaldoCard(
                  saldo: saldo,
                  onTarik: _showTarikSaldoDialog,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Informasi rekening bank gerai Anda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomRekeningInfo(
                  nama: 'Ika Fahriza',
                  bank: 'BCA',
                  norek: '7319709377',
                  nmId: 'NMID01010000000001',
                ),
              ),
              // const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSaldoCard extends StatelessWidget {
  final double saldo;
  final VoidCallback onTarik;
  const CustomSaldoCard({required this.saldo, required this.onTarik, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/saldo_icon.png',
            width: 40,
            height: 40,
            errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 40, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Rp ${saldo.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
              shadowColor: Colors.black26,
            ),
            onPressed: saldo > 0 ? onTarik : null,
            child: const Text(
              'Tarik saldo',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomRekeningInfo extends StatelessWidget {
  final String nama, bank, norek, nmId;
  const CustomRekeningInfo({required this.nama, required this.bank, required this.norek, required this.nmId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nama, style: const TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 8),
        Text(bank, style: const TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 8),
        Text(norek, style: const TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 8),
        Text(nmId, style: const TextStyle(fontSize: 16, color: Colors.black)),
      ],
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  const CustomBottomNavBar({required this.selectedIndex, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8E6E6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavBarItem({required this.icon, required this.label, required this.selected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? Colors.red : Colors.black54, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: selected ? Colors.red : Colors.black54)),
      ],
    );
  }
}
