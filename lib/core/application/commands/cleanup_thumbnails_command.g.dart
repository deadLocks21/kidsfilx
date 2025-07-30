// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleanup_thumbnails_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(cleanupThumbnailsCommand)
const cleanupThumbnailsCommandProvider = CleanupThumbnailsCommandProvider._();

final class CleanupThumbnailsCommandProvider
    extends
        $FunctionalProvider<
          CleanupThumbnailsCommand,
          CleanupThumbnailsCommand,
          CleanupThumbnailsCommand
        >
    with $Provider<CleanupThumbnailsCommand> {
  const CleanupThumbnailsCommandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cleanupThumbnailsCommandProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cleanupThumbnailsCommandHash();

  @$internal
  @override
  $ProviderElement<CleanupThumbnailsCommand> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CleanupThumbnailsCommand create(Ref ref) {
    return cleanupThumbnailsCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CleanupThumbnailsCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CleanupThumbnailsCommand>(value),
    );
  }
}

String _$cleanupThumbnailsCommandHash() =>
    r'3296ad6e8b5b06d05399104317212889ed464acb';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
