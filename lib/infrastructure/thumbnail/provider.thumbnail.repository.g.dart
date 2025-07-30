// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.thumbnail.repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(thumbnailRepository)
const thumbnailRepositoryProvider = ThumbnailRepositoryProvider._();

final class ThumbnailRepositoryProvider
    extends
        $FunctionalProvider<
          ThumbnailRepository,
          ThumbnailRepository,
          ThumbnailRepository
        >
    with $Provider<ThumbnailRepository> {
  const ThumbnailRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thumbnailRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thumbnailRepositoryHash();

  @$internal
  @override
  $ProviderElement<ThumbnailRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ThumbnailRepository create(Ref ref) {
    return thumbnailRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThumbnailRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThumbnailRepository>(value),
    );
  }
}

String _$thumbnailRepositoryHash() =>
    r'bdce62077f1681c72363dadfd9e405e89b7d14b7';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
