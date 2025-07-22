import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidflix/core/domain/services/source_url.repository.dart';
import 'package:kidflix/infrastructure/source_url/provider.source_url.repository.dart';

part 'check_source_url_is_valid_query.g.dart';

@riverpod
CheckSourceUrlIsValidQuery checkSourceUrlIsValidQuery(Ref ref) {
  return CheckSourceUrlIsValidQuery(ref.watch(sourceUrlRepositoryProvider));
}

class CheckSourceUrlIsValidQuery {
  final SourceUrlRepository _sourceUrlRepository;

  CheckSourceUrlIsValidQuery(this._sourceUrlRepository);

  Future<SourceValidationResult> call(String sourceUrl) async {
    return await _sourceUrlRepository.validateUrl(sourceUrl);
  }
}
