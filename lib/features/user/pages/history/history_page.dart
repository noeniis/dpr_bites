import 'package:dpr_bites/features/user/pages/history/receipt_page.dart';
import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/features/user/services/history_page_service.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/favorit/favorit.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HistoryPage extends StatefulWidget {
  final String? initialFilter;
  const HistoryPage({super.key, this.initialFilter});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _storage = const FlutterSecureStorage();
  late String filter;
  String? _userId; // loaded from SharedPreferences
  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;
  String? _error;
  Timer? _autoRefreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 10);

  static const _progressStatuses = [
    'konfirmasi_ketersediaan',
    'konfirmasi_pembayaran',
    'disiapkan',
    'diantar',
    'pickup',
  ];

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      if (_userId == null) {
        // no logged-in user: show empty list and stop loading
        if (mounted) {
          setState(() {
            _orders = [];
            _error = null;
            _loading = false;
          });
        }
        return;
      }
      final result = await HistoryPageService.fetchTransactions(_userId!);
      _orders = result.orders;
      _error = result.error;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    return _orders.where((o) {
      final status = (o['status'] ?? '').toString();
      if (filter == 'berlangsung') return _progressStatuses.contains(status);
      if (filter == 'selesai') return status == 'selesai';
      return status == 'dibatalkan';
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    filter = widget.initialFilter ?? 'berlangsung';
    // Remember this page as last route for simple restoration
    _storage.write(key: 'last_route', value: '/history');
    _init();
  }

  Future<void> _init() async {
    _userId = await HistoryPageService.getUserIdFromPrefs();
    await _fetch();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (t) {
      // Jangan refresh kalau sedang loading manual untuk menghindari tabrakan
      if (!_loading) {
        _silentRefresh();
      }
    });
  }

  Future<void> _silentRefresh() async {
    if (_userId == null) return; // tidak perlu refresh
    try {
      final res = await HistoryPageService.fetchTransactions(_userId!);
      if (res.error != null) return; // diamkan jika error
      final newOrders = res.orders;
      if (_isOrdersChanged(newOrders)) {
        if (mounted) {
          setState(() {
            _orders = newOrders;
            _error = null;
          });
        }
      }
    } catch (_) {
      // silent ignore
    }
  }

  bool _isOrdersChanged(List<Map<String, dynamic>> newOrders) {
    if (newOrders.length != _orders.length) return true;
    for (int i = 0; i < newOrders.length; i++) {
      final a = newOrders[i];
      final b = _orders[i];
      final idA = a['id'] ?? a['transaction_id'] ?? a['kode'] ?? i;
      final idB = b['id'] ?? b['transaction_id'] ?? b['kode'] ?? i;
      if (idA.toString() != idB.toString()) return true; // urutan berubah
      if ((a['status'] ?? '') != (b['status'] ?? ''))
        return true; // status berubah
    }
    return false;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: null,
          title: const Text(
            'Riwayat Pemesanan',
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: SizedBox(
                  height: 54,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ), // gutters left/right
                    child: Row(
                      children: [
                        const SizedBox(width: 4), // left extra gutter
                        _HistoryFilterPill(
                          label: 'Berlangsung',
                          selected: filter == 'berlangsung',
                          icon: Icons.timelapse,
                          onTap: () => setState(() => filter = 'berlangsung'),
                        ),
                        const SizedBox(width: 12),
                        _HistoryFilterPill(
                          label: 'Selesai',
                          selected: filter == 'selesai',
                          icon: Icons.check_circle_outline,
                          onTap: () => setState(() => filter = 'selesai'),
                        ),
                        const SizedBox(width: 12),
                        _HistoryFilterPill(
                          label: 'Dibatalkan',
                          selected: filter == 'dibatalkan',
                          icon: Icons.cancel_outlined,
                          onTap: () => setState(() => filter = 'dibatalkan'),
                        ),
                        const SizedBox(width: 12), // right gutter
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFB03056),
                  backgroundColor: Colors.white,
                  displacement: 18,
                  onRefresh: _fetch,
                  child: _loading
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: CircularProgressIndicator()),
                          ],
                        )
                      : (filteredOrders.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 80,
                                ),
                                children: [
                                  Center(
                                    child: Text(
                                      _error != null
                                          ? 'Error: $_error'
                                          : 'Belum ada Riwayat Pemesanan',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 2,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: filteredOrders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, idx) {
                                  final order = filteredOrders[idx];
                                  return _OrderHistoryCard(
                                    order: order,
                                    onOpen: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ReceiptPage(order: order),
                                        ),
                                      );
                                      await _fetch();
                                    },
                                    progressStatuses: _progressStatuses,
                                  );
                                },
                              )),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _MinimalBottomNav(currentIndex: 1),
      ),
    );
  }
}

class _MinimalBottomNav extends StatelessWidget {
  final int currentIndex;
  const _MinimalBottomNav({required this.currentIndex});

  Color get _primary => const Color(0xFFD53D3D);

  @override
  Widget build(BuildContext context) {
    Widget buildItem({required IconData icon, required int index}) {
      final active = index == currentIndex;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: active
              ? null
              : () {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                      break;
                    case 1:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                      break;
                    case 2:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const FavoritPage()),
                      );
                      break;
                    case 3:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                      break;
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active
                    ? LinearGradient(
                        colors: [_primary, _primary.withOpacity(0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: active ? null : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 26,
                color: active ? Colors.white : _primary.withOpacity(0.7),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            buildItem(icon: Icons.home_rounded, index: 0),
            buildItem(icon: Icons.history_rounded, index: 1),
            buildItem(icon: Icons.favorite_rounded, index: 2),
            buildItem(icon: Icons.person_rounded, index: 3),
          ],
        ),
      ),
    );
  }
}

class _HistoryFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  const _HistoryFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = selected
        ? const LinearGradient(colors: [Color(0xFFD53D3D), Color(0xFFB03056)])
        : const LinearGradient(colors: [Colors.white, Colors.white]);
    final textColor = selected ? Colors.white : const Color(0xFF602829);
    final iconColor = selected ? Colors.white : const Color(0xFFB03056);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 18 : 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? const Color(0xFFD53D3D) : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD53D3D).withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onOpen;
  final List<String> progressStatuses;
  const _OrderHistoryCard({
    required this.order,
    required this.onOpen,
    required this.progressStatuses,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai':
        return const Color(0xFF1B9C68);
      case 'dibatalkan':
        return const Color(0xFFD53D3D);
      default:
        return const Color(0xFFB8832F); // progress / ongoing
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'konfirmasi_ketersediaan':
        return 'Menunggu';
      case 'konfirmasi_pembayaran':
        return 'Konfirmasi';
      case 'disiapkan':
        return 'Disiapkan';
      case 'diantar':
        return 'Diantar';
      case 'pickup':
        return 'Pickup';
      default:
        return status;
    }
  }

  double _progressValue(String status) {
    if (status == 'selesai') return 1;
    if (status == 'dibatalkan')
      return 1; // full bar but colored red/grey overlay
    final idx = progressStatuses.indexOf(status);
    if (idx == -1) return 0; // unknown
    return (idx + 1) / progressStatuses.length;
  }

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? '').toString();
    final priceStr = order['price'] != null
        ? 'Rp${order['price'].toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}'
        : '-';
    final statusColor = _statusColor(status);
    final pv = _progressValue(status);
    final isCancelled = status == 'dibatalkan';
    final isDone = status == 'selesai';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.72),
            border: Border.all(
              color: statusColor.withOpacity(0.16),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            backgroundBlendMode: BlendMode.srcOver,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading icon / avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.14),
                          statusColor.withOpacity(0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: statusColor.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        order['icon'] ?? 'lib/assets/images/spatulaknife.png',
                        width: 26,
                        height: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                order['restaurantName'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              priceStr,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: const Color(
                                  0xFF602829,
                                ).withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _StatusBadge(
                              label: _statusLabel(status),
                              color: statusColor,
                              subtle: !(isDone || isCancelled),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order['dateDisplay'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!(isDone || isCancelled)) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.06),
                                Colors.black.withOpacity(0.04),
                              ],
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pv.clamp(0, 1),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor.withOpacity(0.9),
                                  statusColor.withOpacity(0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                const SizedBox(height: 12),
              ],
              Row(
                children: const [
                  Text(
                    'Lihat Struk',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB03056),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Color(0xFFB03056),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool subtle;
  const _StatusBadge({
    required this.label,
    required this.color,
    this.subtle = false,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: subtle
            ? LinearGradient(
                colors: [color.withOpacity(0.20), color.withOpacity(0.08)],
              )
            : LinearGradient(colors: [color, color.withOpacity(0.8)]),
        border: Border.all(
          color: color.withOpacity(subtle ? 0.35 : 0.55),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: subtle ? color.darken(0.1) : Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

extension _ColorShade on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final f = 1 - amount;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }
}
