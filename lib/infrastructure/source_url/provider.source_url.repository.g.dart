// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.source_url.repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(sourceUrlRepository)
const sourceUrlRepositoryProvider = SourceUrlRepositoryProvider._();

final class SourceUrlRepositoryProvider
    extends
        $FunctionalProvider<
          SourceUrlRepository,
          SourceUrlRepository,
          SourceUrlRepository
        >
    with $Provider<SourceUrlRepository> {
  const SourceUrlRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceUrlRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceUrlRepositoryHash();

  @$internal
  @override
  $ProviderElement<SourceUrlRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SourceUrlRepository create(Ref ref) {
    return sourceUrlRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceUrlRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceUrlRepository>(value),
    );
  }
}

String _$sourceUrlRepositoryHash() =>
    r'95f9e9e8ed1459cc9e3317f10ac9052d8d4c3977';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
