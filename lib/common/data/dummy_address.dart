class DummyAddress {
  final String namaPenerima; // VARCHAR(50)
  final String namaGedung; // VARCHAR(100)
  final String detailPengantaran; // TEXT
  final String noHp; // VARCHAR(13)
  final bool isDefault; // alamat utama
  final double? latitude;
  final double? longitude;
  final String? alamatLengkapMaps;

  const DummyAddress({
    required this.namaPenerima,
    required this.namaGedung,
    required this.detailPengantaran,
    required this.noHp,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    this.alamatLengkapMaps,
  });
}

// Dummy data alamat
const List<DummyAddress> dummyAddresses = [
  DummyAddress(
    namaPenerima: 'Raihan Ahmad',
    namaGedung: 'Gedung Nusantara I',
    detailPengantaran: 'Lantai 3, Ruang Rapat Komisi A, dekat lift timur',
    noHp: '081234567890',
    isDefault: true,
    latitude: -6.209064130877545,
    longitude: 106.79965206041742,
    alamatLengkapMaps: 'Kompleks DPR/MPR RI, Senayan, Jakarta',
  ),
  DummyAddress(
    namaPenerima: 'Siti Nurhaliza',
    namaGedung: 'Menara Harmoni',
    detailPengantaran: 'Lobby utama, titip ke resepsionis',
    noHp: '081298765432',
    latitude: -6.1751,
    longitude: 106.8650,
    alamatLengkapMaps: 'Jakarta Pusat, DKI Jakarta',
  ),
];
