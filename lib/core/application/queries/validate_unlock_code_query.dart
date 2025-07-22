import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidflix/core/domain/services/unlock-code.repository.dart';
import 'package:kidflix/infrastructure/unlock_code/provider.unlock-code.repository.dart';

part 'validate_unlock_code_query.g.dart';

class ValidateUnlockCodeQuery {
  ValidateUnlockCodeQuery(this._repository);

  final UnlockCodeRepository _repository;

  Future<bool> validateCode(String code) async {
    return await _repository.isValid(code);
  }
}

@riverpod
ValidateUnlockCodeQuery validateUnlockCodeQuery(Ref ref) {
  final repository = ref.watch(unlockCodeRepositoryProvider);
  return ValidateUnlockCodeQuery(repository);
}
