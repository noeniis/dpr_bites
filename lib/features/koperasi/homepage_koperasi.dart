import 'package:flutter/material.dart';
import 'dart:async';
import '../../app/gradient_background.dart';
import '../../common/widgets/custom_widgets.dart';
import 'pengajuan_detail_page.dart';
import 'pengajuan_service.dart';

class HomepageKoperasi extends StatefulWidget {
  const HomepageKoperasi({Key? key}) : super(key: key);

  @override
  State<HomepageKoperasi> createState() => _HomepageKoperasiState();
}

class _HomepageKoperasiState extends State<HomepageKoperasi> {
  // Tambahkan timer untuk auto-refresh
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Timer? _refreshTimer;

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadPengajuan();
    });
  }
  String filterStatus = 'pending';
  Future<List<Map<String, dynamic>>>? _futurePengajuan;

  @override
  void initState() {
  super.initState();
  _loadPengajuan();
  _startAutoRefresh();
  }

  void logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _loadPengajuan() {
    setState(() {
      _futurePengajuan = PengajuanService.fetchPengajuan(filterStatus);
    });
  }

  void _onFilterChange(String status) {
    setState(() {
      filterStatus = status;
    });
    _loadPengajuan();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Koperasi DPR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Logout',
              onPressed: logout,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomFilterChip(
                    label: 'Pending',
                    selected: filterStatus == 'pending',
                    onTap: () => _onFilterChange('pending'),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Diterima',
                    selected: filterStatus == 'approved',
                    onTap: () => _onFilterChange('approved'),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Ditolak',
                    selected: filterStatus == 'rejected',
                    onTap: () => _onFilterChange('rejected'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futurePengajuan,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada pengajuan'));
                  }
                  final pengajuanList = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pengajuanList.length,
                    itemBuilder: (context, i) {
                      final data = pengajuanList[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CustomEmptyCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage('lib/assets/images/iconCamera.png'),
                              radius: 28,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(data['nama_lengkap'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(data['nama_gerai'] ?? '-'),
                            trailing: Text((data['status_pengajuan'] ?? '').toString().toUpperCase(),
                              style: TextStyle(
                                color: (data['status_pengajuan'] ?? '') == 'pending'
                                    ? Colors.orange
                                    : (data['status_pengajuan'] ?? '') == 'approved'
                                        ? Colors.green
                                        : Colors.red,
                                fontWeight: FontWeight.bold,
                              )),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PengajuanDetailPage(data: data),
                                ),
                              );
                              if (result == 'approved') {
                                _onFilterChange('approved');
                              } else if (result == 'rejected') {
                                _onFilterChange('rejected');
                              } else if (result == 'pending') {
                                _onFilterChange('pending');
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
