import 'package:flutter/material.dart';
import '../../app/gradient_background.dart';
import 'alasan_tolak_page.dart';
import '../../common/widgets/custom_widgets.dart';
import 'services/pengajuan_service.dart';
import 'models/pengajuan_model.dart';

class PengajuanDetailPage extends StatelessWidget {
  final PengajuanModel data;
  const PengajuanDetailPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(data.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  data.namaGerai,
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
              if (data.statusPengajuan == 'pending')
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
                                  print('DEBUG id_gerai: ${data.idGerai}'); // debug
                                  await PengajuanService.updateStatus(data.idGerai, 'rejected', alasan: alasan);
                                  Navigator.pop(context); // pop alasan
                                  Navigator.pop(context, 'ditolak'); // pop detail, return status
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
                          await PengajuanService.updateStatus(data.idGerai, 'approved');
                          Navigator.pop(context, 'approved'); 
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
  final PengajuanModel data;
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
  final PengajuanModel data;
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
  final PengajuanModel data;
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
              child: data.fotoKtpPath != null && data.fotoKtpPath!.isNotEmpty
                  ? Image.network(
                      data.fotoKtpPath!,
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
          _InfoLine(label: 'Nama Lengkap', value: data.namaLengkap),
          _InfoLine(label: 'NIK', value: data.nik ?? '-'),
          _InfoLine(label: 'Tempat Lahir', value: data.tempatLahir ?? '-'),
          _InfoLine(label: 'Tanggal Lahir', value: data.tanggalLahir ?? '-'),
          _InfoLine(label: 'Jenis Kelamin', value: data.jenisKelamin ?? '-'),
        ],
      ),
    );
  }
}

class _DataGerai extends StatelessWidget {
  final PengajuanModel data;
  const _DataGerai({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(label: 'Nama Gerai', value: data.namaGerai),
          _InfoLine(label: 'Alamat', value: data.detailAlamat ?? '-'),
          const SizedBox(height: 8),
          _InfoLine(label: 'Hari Buka', value: data.hariBuka ?? '-'),
          _InfoLine(label: 'Jam Buka', value: data.jamBuka ?? '-'),
          _InfoLine(label: 'Jam Tutup', value: data.jamTutup ?? '-'),
          const SizedBox(height: 8),
          const Text('Foto QRIS:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: data.qrisPath != null && data.qrisPath!.isNotEmpty
                  ? Image.network(
                      data.qrisPath!,
                      width: 240,
                      height: 300,
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
