
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  /// Always return id_users as String if possible, otherwise null.
  static Future<String?> getUserIdString() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('id_users');
    } catch (_) {}
    return null;
  }
}
