// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_thumbnail_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(getThumbnailQuery)
const getThumbnailQueryProvider = GetThumbnailQueryProvider._();

final class GetThumbnailQueryProvider
    extends
        $FunctionalProvider<
          GetThumbnailQuery,
          GetThumbnailQuery,
          GetThumbnailQuery
        >
    with $Provider<GetThumbnailQuery> {
  const GetThumbnailQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getThumbnailQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getThumbnailQueryHash();

  @$internal
  @override
  $ProviderElement<GetThumbnailQuery> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetThumbnailQuery create(Ref ref) {
    return getThumbnailQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetThumbnailQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetThumbnailQuery>(value),
    );
  }
}

String _$getThumbnailQueryHash() => r'8c942957d71440cf0871d45fda187a864ff05637';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
