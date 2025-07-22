import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidflix/core/domain/services/unlock-code.repository.dart';
import 'package:kidflix/infrastructure/unlock_code/provider.unlock-code.repository.dart';

part 'update_unlock_code_command.g.dart';

class UpdateUnlockCodeCommand {
  UpdateUnlockCodeCommand(this._repository);

  final UnlockCodeRepository _repository;

  Future<void> updateCode(String oldCode, String newCode) async {
    await _repository.update(oldCode, newCode);
  }
}

@riverpod
UpdateUnlockCodeCommand updateUnlockCodeCommand(Ref ref) {
  final repository = ref.watch(unlockCodeRepositoryProvider);
  return UpdateUnlockCodeCommand(repository);
}
