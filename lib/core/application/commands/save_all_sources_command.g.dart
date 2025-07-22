// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_all_sources_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(saveAllSourcesCommand)
const saveAllSourcesCommandProvider = SaveAllSourcesCommandProvider._();

final class SaveAllSourcesCommandProvider
    extends
        $FunctionalProvider<
          SaveAllSourcesCommand,
          SaveAllSourcesCommand,
          SaveAllSourcesCommand
        >
    with $Provider<SaveAllSourcesCommand> {
  const SaveAllSourcesCommandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveAllSourcesCommandProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveAllSourcesCommandHash();

  @$internal
  @override
  $ProviderElement<SaveAllSourcesCommand> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveAllSourcesCommand create(Ref ref) {
    return saveAllSourcesCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveAllSourcesCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveAllSourcesCommand>(value),
    );
  }
}

String _$saveAllSourcesCommandHash() =>
    r'f54ace919d67136d0226e47305b5e5f436f0ccb4';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
