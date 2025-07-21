// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_sources_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(getAllSourcesQuery)
const getAllSourcesQueryProvider = GetAllSourcesQueryProvider._();

final class GetAllSourcesQueryProvider
    extends
        $FunctionalProvider<
          GetAllSourcesQuery,
          GetAllSourcesQuery,
          GetAllSourcesQuery
        >
    with $Provider<GetAllSourcesQuery> {
  const GetAllSourcesQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getAllSourcesQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getAllSourcesQueryHash();

  @$internal
  @override
  $ProviderElement<GetAllSourcesQuery> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetAllSourcesQuery create(Ref ref) {
    return getAllSourcesQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetAllSourcesQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetAllSourcesQuery>(value),
    );
  }
}

String _$getAllSourcesQueryHash() =>
    r'ff6100430da2df3f3700f549a9834366ef2a00f5';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
