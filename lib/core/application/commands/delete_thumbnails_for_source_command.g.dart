// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_thumbnails_for_source_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(deleteThumbnailsForSourceCommand)
const deleteThumbnailsForSourceCommandProvider =
    DeleteThumbnailsForSourceCommandProvider._();

final class DeleteThumbnailsForSourceCommandProvider
    extends
        $FunctionalProvider<
          DeleteThumbnailsForSourceCommand,
          DeleteThumbnailsForSourceCommand,
          DeleteThumbnailsForSourceCommand
        >
    with $Provider<DeleteThumbnailsForSourceCommand> {
  const DeleteThumbnailsForSourceCommandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteThumbnailsForSourceCommandProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteThumbnailsForSourceCommandHash();

  @$internal
  @override
  $ProviderElement<DeleteThumbnailsForSourceCommand> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteThumbnailsForSourceCommand create(Ref ref) {
    return deleteThumbnailsForSourceCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteThumbnailsForSourceCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteThumbnailsForSourceCommand>(
        value,
      ),
    );
  }
}

String _$deleteThumbnailsForSourceCommandHash() =>
    r'1eb67c9f5fb7ab37cdf356bb3d0316d458789910';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
