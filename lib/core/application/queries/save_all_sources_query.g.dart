// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_all_sources_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(saveAllSourcesQuery)
const saveAllSourcesQueryProvider = SaveAllSourcesQueryProvider._();

final class SaveAllSourcesQueryProvider
    extends
        $FunctionalProvider<
          SaveAllSourcesQuery,
          SaveAllSourcesQuery,
          SaveAllSourcesQuery
        >
    with $Provider<SaveAllSourcesQuery> {
  const SaveAllSourcesQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveAllSourcesQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveAllSourcesQueryHash();

  @$internal
  @override
  $ProviderElement<SaveAllSourcesQuery> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveAllSourcesQuery create(Ref ref) {
    return saveAllSourcesQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveAllSourcesQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveAllSourcesQuery>(value),
    );
  }
}

String _$saveAllSourcesQueryHash() =>
    r'cd601cd5fee492e8d232cbac36194882b636ebdc';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
