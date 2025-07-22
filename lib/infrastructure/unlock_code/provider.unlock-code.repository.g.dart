// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.unlock-code.repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(unlockCodeRepository)
const unlockCodeRepositoryProvider = UnlockCodeRepositoryProvider._();

final class UnlockCodeRepositoryProvider
    extends
        $FunctionalProvider<
          UnlockCodeRepository,
          UnlockCodeRepository,
          UnlockCodeRepository
        >
    with $Provider<UnlockCodeRepository> {
  const UnlockCodeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unlockCodeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unlockCodeRepositoryHash();

  @$internal
  @override
  $ProviderElement<UnlockCodeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UnlockCodeRepository create(Ref ref) {
    return unlockCodeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnlockCodeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnlockCodeRepository>(value),
    );
  }
}

String _$unlockCodeRepositoryHash() =>
    r'4eff8154ffe26ae27fbd1c8b99d853feab222934';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
