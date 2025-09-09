import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  /// Return id_users as int if possible, otherwise null.
  static Future<int?> getUserIdInt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final i = prefs.getInt('id_users');
      if (i != null) return i;
      final s = prefs.getString('id_users');
      if (s != null) return int.tryParse(s);
    } catch (_) {}
    return null;
  }

  /// Return id_users as String if possible, otherwise null.
  static Future<String?> getUserIdString() async {
    final i = await getUserIdInt();
    if (i != null) return i.toString();
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('id_users');
    } catch (_) {}
    return null;
  }
}
