class AlasanTolakModel {
  final List<String> shortcutAlasan;
  final Set<String> selectedAlasan;
  String alasanLain;

  AlasanTolakModel({
    List<String>? shortcutAlasan,
    Set<String>? selectedAlasan,
    this.alasanLain = '',
  })  : shortcutAlasan = shortcutAlasan ?? [
          'Data kurang lengkap',
          'Foto KTP buram',
          'Data tidak valid',
          'Dokumen tidak sesuai',
        ],
        selectedAlasan = selectedAlasan ?? {};

  void toggleAlasan(String alasan, bool selected) {
    if (selected) {
      selectedAlasan.add(alasan);
    } else {
      selectedAlasan.remove(alasan);
    }
  }

  List<String> get alasanList {
    return [
      ...selectedAlasan,
      if (alasanLain.trim().isNotEmpty) alasanLain.trim(),
    ];
  }

  String get alasanGabung => alasanList.join('; ');
}
