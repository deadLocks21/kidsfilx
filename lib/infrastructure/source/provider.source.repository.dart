import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/domain/services/source.repository.dart';
import '../../shared/dependancy_injection.dart';
import 'shared_preferences.source.repository.dart';
import 'in-memory.source.repository.dart';

part 'provider.source.repository.g.dart';

@riverpod
SourceRepository sourceRepository(Ref ref) {
  if (DependancyInjection.isProduction) {
    return SharedPreferencesSourceRepository();
  }
  return InMemorySourceRepository();
}
