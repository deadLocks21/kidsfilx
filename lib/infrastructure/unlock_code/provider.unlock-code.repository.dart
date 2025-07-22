import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidflix/core/domain/services/unlock-code.repository.dart';
import 'package:kidflix/infrastructure/unlock_code/in-memory.unlock-code.repository.dart';
import 'package:kidflix/infrastructure/unlock_code/shared_preferences.unlock-code.repository.dart';
import 'package:kidflix/shared/dependancy_injection.dart';

part 'provider.unlock-code.repository.g.dart';

@riverpod
UnlockCodeRepository unlockCodeRepository(Ref ref) {
  if (DependancyInjection.isProduction) {
    return SharedPreferencesUnlockCodeRepository();
  }
  return InMemoryUnlockCodeRepository();
}
