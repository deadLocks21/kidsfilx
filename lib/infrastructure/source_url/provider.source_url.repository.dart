import 'package:kidflix/shared/dependancy_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidflix/core/domain/services/source_url.repository.dart';
import 'package:kidflix/infrastructure/source_url/http.source_url.repository.dart';
import 'package:kidflix/infrastructure/source_url/in-memory.source_url.repository.dart';

part 'provider.source_url.repository.g.dart';

@riverpod
SourceUrlRepository sourceUrlRepository(Ref ref) {
  if (DependancyInjection.isProduction) {
    return HttpSourceRepository();
  }

  return InMemorySourceUrlRepository();
}
