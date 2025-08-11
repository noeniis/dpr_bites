class DummyAddress {
  final String namaPenerima; // VARCHAR(50)
  final String namaGedung; // VARCHAR(100)
  final String detailPengantaran; // TEXT
  final String noHp; // VARCHAR(13)
  final bool isDefault; // alamat utama

  const DummyAddress({
    required this.namaPenerima,
    required this.namaGedung,
    required this.detailPengantaran,
    required this.noHp,
    this.isDefault = false,
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
  ),
  DummyAddress(
    namaPenerima: 'Siti Nurhaliza',
    namaGedung: 'Menara Harmoni',
    detailPengantaran: 'Lobby utama, titip ke resepsionis',
    noHp: '081298765432',
  ),
];
