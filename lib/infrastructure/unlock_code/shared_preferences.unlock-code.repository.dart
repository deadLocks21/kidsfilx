import 'package:kidflix/core/domain/services/unlock-code.repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUnlockCodeRepository implements UnlockCodeRepository {
  static const String _key = 'unlock_code';
  static const String _defaultCode = '1234';

  @override
  Future<bool> isValid(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString(_key) ?? _defaultCode;
    return code == storedCode;
  }

  @override
  Future<void> update(String oldCode, String newCode) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCode = prefs.getString(_key) ?? _defaultCode;

    if (oldCode != currentCode) {
      throw Exception('Ancien code incorrect');
    }

    await prefs.setString(_key, newCode);
  }
}
