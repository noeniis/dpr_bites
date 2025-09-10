import 'package:dpr_bites/features/seller/services/gerai_profil_service.dart';

class HalalStatusService {
  // Get halal status as 'ya' or 'tidak'
  static Future<String> getHalalStatus(String idUsers) async {
    final val = await GeraiProfilService.getHalalStatus(idUsers);
    return val == '1' ? 'ya' : 'tidak';
  }

  // Save halal status
  static Future<bool> saveHalalStatus(String idUsers, String? selectedOption) async {
    String sertifikasiHalal = '0';
    if (selectedOption == 'ya') {
      sertifikasiHalal = '1';
    }
    return await GeraiProfilService.addOrUpdateHalal(
      idUsers: idUsers,
      sertifikasiHalal: sertifikasiHalal,
    );
  }
}
