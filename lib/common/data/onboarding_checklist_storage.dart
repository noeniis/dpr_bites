import 'package:shared_preferences/shared_preferences.dart';

class OnboardingChecklistStorage {
  /// Force reset checklist ke [false, false, false] (belum selesai semua)
  static Future<void> forceReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyChecklist, ['false', 'false', 'false']);
  }
  static const _keyChecklist = 'onboarding_checklist_status';

  // status: [card1, card2, card3] (true = selesai)
  static Future<List<bool>> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyChecklist);
    if (list == null || list.length != 3) {
      return [false, false, false];
    }
    return list.map((e) => e == 'true').toList();
  }

  static Future<void> setStatus(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getStatus();
    current[index] = value;
    await prefs.setStringList(_keyChecklist, current.map((e) => e.toString()).toList());
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyChecklist);
  }

  static Future<void> resetChecklist() async {
    await OnboardingChecklistStorage.reset();
  }
}
