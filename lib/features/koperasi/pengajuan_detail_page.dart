import 'package:flutter/material.dart';
import '../../app/gradient_background.dart';
import 'alasan_tolak_page.dart';
import '../../common/widgets/custom_widgets.dart';
import 'pengajuan_service.dart';

class PengajuanDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const PengajuanDetailPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(data['nama_lengkap'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  data['nama_gerai'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _DataDiriPenjualPage(data: data),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.person, size: 36, color: Colors.blue),
                              SizedBox(height: 8),
                              Text('Data Diri Penjual', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _DataGeraiPage(data: data),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.store, size: 36, color: Colors.green),
                              SizedBox(height: 8),
                              Text('Data Gerai', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if ((data['status_pengajuan'] ?? 'pending') == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomButtonKotak(
                        text: 'Tolak',
                        backgroundColor: Colors.red[400],
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlasanTolakPage(
                                onSubmit: (alasan) async {
                                  await PengajuanService.updateStatus(data['id_gerai'], 'rejected', alasan: alasan);
                                  Navigator.pop(context); // pop alasan
                                  Navigator.pop(context, 'rejected'); // pop detail, return status
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButtonKotak(
                        text: 'Terima',
                        backgroundColor: Colors.green[600],
                        textColor: Colors.white,
                        onPressed: () async {
                          await PengajuanService.updateStatus(data['id_gerai'], 'approved');
                          Navigator.pop(context, 'approved'); // pop detail, return status
                        },
                      ),
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

class _DataDiriPenjualPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DataDiriPenjualPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Data Diri Penjual'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _DataDiriPenjual(data: data),
        ),
      ),
    );
  }
}

class _DataGeraiPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DataGeraiPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Data Gerai'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _DataGerai(data: data),
        ),
      ),
    );
  }
}

class _DataDiriPenjual extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DataDiriPenjual({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: data['foto_ktp_path'] != null && data['foto_ktp_path'].toString().isNotEmpty
                  ? Image.network(
                      data['foto_ktp_path'],
                      width: 180,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'lib/assets/images/ktp_dummy.jpg',
                      width: 180,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoLine(label: 'Nama Lengkap', value: data['nama_lengkap'] ?? '-'),
          _InfoLine(label: 'NIK', value: data['nik'] ?? '-'),
          _InfoLine(label: 'Tempat Lahir', value: data['tempat_lahir'] ?? '-'),
          _InfoLine(label: 'Tanggal Lahir', value: data['tanggal_lahir'] ?? '-'),
          _InfoLine(label: 'Jenis Kelamin', value: data['jenis_kelamin'] ?? '-'),
        ],
      ),
    );
  }
}

class _DataGerai extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DataGerai({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(label: 'Nama Gerai', value: data['nama_gerai'] ?? '-'),
          _InfoLine(label: 'Alamat', value: data['detail_alamat'] ?? '-'),
          _InfoLine(label: 'Sertifikasi Halal', value: (data['sertifikasi_halal'] == '1' || data['sertifikasi_halal'] == true) ? 'Ya' : 'Tidak'),
          const SizedBox(height: 8),
          const Text('Foto QRIS:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: data['qris_path'] != null && data['qris_path'].toString().isNotEmpty
                  ? Image.network(
                      data['qris_path'],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'lib/assets/images/iconQR.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoLine(label: 'Hari Buka', value: data['hari_buka'] ?? '-'),
          _InfoLine(label: 'Jam Buka', value: data['jam_buka'] ?? '-'),
          _InfoLine(label: 'Jam Tutup', value: data['jam_tutup'] ?? '-'),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
