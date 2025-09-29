import 'package:flutter/material.dart';
import 'dart:async';
import '../../app/gradient_background.dart';
import '../../common/widgets/custom_widgets.dart';
import 'pengajuan_detail_page.dart';
import 'services/pengajuan_service.dart';
import 'models/pengajuan_model.dart';
import 'package:dpr_bites/features/auth/pages/logout.dart';

class HomepageKoperasi extends StatefulWidget {
  const HomepageKoperasi({Key? key}) : super(key: key);

  @override
  State<HomepageKoperasi> createState() => _HomepageKoperasiState();
}

class _HomepageKoperasiState extends State<HomepageKoperasi> {
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Timer? _refreshTimer;

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadPengajuan();
    });
  }
  String filterStatus = 'pending';
  Future<List<PengajuanModel>>? _futurePengajuan;

  @override
  void initState() {
  super.initState();
  _loadPengajuan();
  _startAutoRefresh();
  }

  void handleLogout() async {
    await logout(context);
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
              onPressed: handleLogout,
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
              child: FutureBuilder<List<PengajuanModel>>(
                future: _futurePengajuan,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada pengajuan'));
                  }
                  final pengajuanList = snapshot.data!;
                  // Urutkan dari yang paling baru (idGerai terbesar) di atas
                  List<PengajuanModel> sortedList = List.from(pengajuanList);
                  sortedList.sort((a, b) => b.idGerai.compareTo(a.idGerai));
                  List<PengajuanModel> filteredList;
                  if (filterStatus == 'pending') {
                    filteredList = sortedList.where((data) {
                      return (data.step1?.toString() == '1' && data.step2?.toString() == '1');
                    }).toList();
                  } else {
                    filteredList = sortedList;
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, i) {
                      final data = filteredList[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CustomEmptyCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage('lib/assets/images/dummy profile.jpeg'),
                              radius: 28,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(data.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(data.namaGerai),
                            trailing: Text(data.statusPengajuan.toUpperCase(),
                              style: TextStyle(
                                color: data.statusPengajuan == 'pending'
                                    ? Colors.orange
                                    : data.statusPengajuan == 'approved'
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
