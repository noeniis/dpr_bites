
import 'package:flutter/material.dart';
import '../../app/gradient_background.dart';
import '../../common/widgets/custom_widgets.dart';
import '../../common/data/dummy_pengajuan_koperasi.dart';
import '../../common/data/dummy_profile_koperasi.dart';

class HomepageKoperasi extends StatefulWidget {
  const HomepageKoperasi({Key? key}) : super(key: key);

  @override
  State<HomepageKoperasi> createState() => _HomepageKoperasiState();
}

class _HomepageKoperasiState extends State<HomepageKoperasi> {
  void logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
  String filterStatus = 'pending';

  void updateStatus(int index, String status) {
    setState(() {
      dummyPengajuanKoperasi[index]['status'] = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = dummyPengajuanKoperasi
        .asMap()
        .entries
        .where((e) => (e.value['status'] ?? '') == filterStatus)
        .toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(dummyProfileKoperasi['foto'] ?? ''),
                radius: 18,
                child: const Icon(Icons.account_balance, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dummyProfileKoperasi['nama'] ?? 'Koperasi',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
                    onTap: () => setState(() => filterStatus = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Diterima',
                    selected: filterStatus == 'diterima',
                    onTap: () => setState(() => filterStatus = 'diterima'),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Ditolak',
                    selected: filterStatus == 'ditolak',
                    onTap: () => setState(() => filterStatus = 'ditolak'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Tidak ada pengajuan'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final idx = filtered[i].key;
                        final data = filtered[i].value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomEmptyCard(
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: AssetImage('lib/assets/images/profile_dummy.png'),
                                    radius: 28,
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.verified_user, color: Colors.blue, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(data['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(data['namaToko'] ?? '-'),
                              trailing: Text((data['status'] ?? '').toString().toUpperCase(), style: TextStyle(
                                color: (data['status'] ?? '') == 'pending' ? Colors.orange : (data['status'] ?? '') == 'diterima' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              )),
                              onTap: () {
                                String alasanTolak = '';
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  builder: (_) => Padding(
                                    padding: MediaQuery.of(context).viewInsets,
                                    child: DraggableScrollableSheet(
                                      expand: false,
                                      initialChildSize: 0.8,
                                      minChildSize: 0.5,
                                      maxChildSize: 0.95,
                                      builder: (context, scrollController) {
                                        return StatefulBuilder(
                                          builder: (context, setModalState) {
                                            return SingleChildScrollView(
                                              controller: scrollController,
                                              child: Padding(
                                                padding: const EdgeInsets.all(24),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundImage: AssetImage('lib/assets/images/profile_dummy.png'),
                                                          radius: 32,
                                                          child: const Icon(Icons.person, color: Colors.white),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(data['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                            Text(data['namaToko'] ?? '-', style: const TextStyle(fontSize: 15)),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 18),
                                                    Container(
                                                      margin: const EdgeInsets.only(bottom: 12),
                                                      child: TextButton.icon(
                                                        icon: const Icon(Icons.image, color: Colors.blue),
                                                        label: const Text('Lihat Foto KTP', style: TextStyle(color: Colors.blue)),
                                                        style: TextButton.styleFrom(
                                                          padding: EdgeInsets.zero,
                                                          minimumSize: const Size(0, 0),
                                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          alignment: Alignment.centerLeft,
                                                        ),
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (_) => Dialog(
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(12),
                                                                child: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    ClipRRect(
                                                                      borderRadius: BorderRadius.circular(12),
                                                                      child: Image.asset(
                                                                        data['fotoKtp'] ?? '',
                                                                        width: 180,
                                                                        height: 135,
                                                                        fit: BoxFit.cover,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 8),
                                                                    const Text('Preview Foto KTP'),
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(context),
                                                                      child: const Text('Tutup'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    TextFieldLine(label: 'Email', value: data['email'] ?? '-'),
                                                    TextFieldLine(label: 'No Telepon', value: data['noTelepon'] ?? '-'),
                                                    TextFieldLine(label: 'NIK', value: data['nik'] ?? '-'),
                                                    TextFieldLine(label: 'Tempat Lahir', value: data['tempatLahir'] ?? '-'),
                                                    TextFieldLine(label: 'Tanggal Lahir', value: data['tanggalLahir'] ?? '-'),
                                                    TextFieldLine(label: 'Jenis Kelamin', value: data['jenisKelamin'] ?? '-'),
                                                    TextFieldLine(label: 'Lokasi Toko', value: data['lokasiToko'] ?? '-'),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                                        const SizedBox(width: 6),
                                                        Text('Diajukan: 2025-08-01', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 24),
                                                    if ((data['status'] ?? '') == 'pending')
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: CustomButtonKotak(
                                                              text: 'Tolak',
                                                              backgroundColor: Colors.red[400],
                                                              onPressed: () {
                                                                showDialog(
                                                                  context: context,
                                                                  builder: (ctx) => AlertDialog(
                                                                    title: const Text('Alasan Penolakan'),
                                                                    content: TextField(
                                                                      autofocus: true,
                                                                      maxLines: 3,
                                                                      decoration: const InputDecoration(hintText: 'Masukkan alasan penolakan'),
                                                                      onChanged: (val) {
                                                                        alasanTolak = val;
                                                                      },
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () {
                                                                          if (alasanTolak.trim().isEmpty) return;
                                                                          Navigator.pop(ctx);
                                                                          Navigator.pop(context);
                                                                          updateStatus(idx, 'ditolak');
                                                                        },
                                                                        child: const Text('Kirim'),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: CustomButtonKotak(
                                                              text: 'Terima',
                                                              backgroundColor: Colors.green[600],
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                                updateStatus(idx, 'diterima');
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
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
