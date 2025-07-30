// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_thumbnail_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(generateThumbnailQuery)
const generateThumbnailQueryProvider = GenerateThumbnailQueryProvider._();

final class GenerateThumbnailQueryProvider
    extends
        $FunctionalProvider<
          GenerateThumbnailQuery,
          GenerateThumbnailQuery,
          GenerateThumbnailQuery
        >
    with $Provider<GenerateThumbnailQuery> {
  const GenerateThumbnailQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'generateThumbnailQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$generateThumbnailQueryHash();

  @$internal
  @override
  $ProviderElement<GenerateThumbnailQuery> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GenerateThumbnailQuery create(Ref ref) {
    return generateThumbnailQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GenerateThumbnailQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GenerateThumbnailQuery>(value),
    );
  }
}

String _$generateThumbnailQueryHash() =>
    r'd2ea48ef2d56db94e7c402437c174eb3865c5cab';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
