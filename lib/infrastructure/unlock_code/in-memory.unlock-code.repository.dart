import 'package:kidflix/core/domain/services/unlock-code.repository.dart';

class InMemoryUnlockCodeRepository implements UnlockCodeRepository {
  InMemoryUnlockCodeRepository._({String? initialCode}) {
    if (initialCode != null) {
      _currentCode = initialCode;
    }
  }

  static InMemoryUnlockCodeRepository? _instance;
  static String _currentCode = "1234";

  factory InMemoryUnlockCodeRepository({String? initialCode}) {
    _instance ??= InMemoryUnlockCodeRepository._(initialCode: initialCode);
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }

  @override
  Future<bool> isValid(String code) async {
    return code == _currentCode;
  }

  @override
  Future<void> update(String oldCode, String newCode) async {
    if (oldCode != _currentCode) {
      throw Exception('Ancien code incorrect');
    }
    _currentCode = newCode;
  }
}
