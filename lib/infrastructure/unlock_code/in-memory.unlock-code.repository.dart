import 'package:kidflix/core/domain/services/unlock-code.repository.dart';

class InMemoryUnlockCodeRepository implements UnlockCodeRepository {
  InMemoryUnlockCodeRepository({String? initialCode})
    : _currentCode = initialCode ?? "1234";

  String _currentCode;

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
