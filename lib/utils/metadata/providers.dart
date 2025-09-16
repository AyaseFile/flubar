import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/extensions/properties_extension.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/rust/api/id3.dart';
import 'package:flubar/rust/api/lofty.dart';
import 'package:flubar/ui/dialogs/cover_dialog/providers.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class MetadataUtil extends _$MetadataUtil {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> writeMetadata() async {
    state = const AsyncValue.loading();

    final writeToMemoryOnly = ref
        .read(metadataSettingsProvider)
        .writeToMemoryOnly;
    if (writeToMemoryOnly) {
      final id = ref.read(playlistIdProvider).selectedId;
      final selectedTracks = ref.read(selectedTracksProvider);
      ref.read(playlistsProvider.notifier).updateTracks(id, selectedTracks);
      return true;
    }

    final force = ref.read(metadataSettingsProvider).forceWriteMetadata;
    final id = ref.read(playlistIdProvider).selectedId;
    final selectedTracks = ref.read(selectedTracksProvider);
    final updatedTracks = <Track>[];
    var failed = 0;
    await Future.wait(
      selectedTracks.map((t) async {
        if (t.properties.isCue()) {
          // 对于 cue, 不写入元数据, 只更新内存中的元数据
          updatedTracks.add(t);
          return;
        }
        try {
          await loftyWriteMetadata(
            metadata: t.metadata,
            file: t.path,
            force: force,
          );
          updatedTracks.add(t);
        } catch (loftyError) {
          if (force) {
            failed++;
            globalTalker.error('无法强制更新元数据: ${t.path}', loftyError);
            return;
          }
          try {
            await id3WriteMetadata(metadata: t.metadata, file: t.path);
            updatedTracks.add(t);
          } catch (id3Error) {
            failed++;
            globalTalker.error('无法更新元数据: ${t.path}', [loftyError, id3Error]);
          }
        }
      }),
    );
    ref.read(playlistsProvider.notifier).updateTracks(id, updatedTracks);
    state = const AsyncValue.data(null);
    if (failed != 0) {
      showExceptionSnackbar(title: '错误', message: '无法更新 $failed 个文件的元数据');
      return false;
    }
    return true;
  }

  Future<void> writeCover(bool batch) async {
    state = const AsyncValue.loading();

    final writeToMemoryOnly = ref
        .read(metadataSettingsProvider)
        .writeToMemoryOnly;
    if (writeToMemoryOnly) {
      final id = ref.read(playlistIdProvider).selectedId;
      final coverModel = batch
          ? ref.read(batchedTrackCoverProvider)
          : ref.read(groupedTrackCoverProvider);
      final updatedTracks = coverModel
          .map((cover) {
            final frontCover = cover.newCover;
            return cover.tracks.map((t) {
              final metadata = t.metadata.nullableCopyWith(
                frontCover: () => frontCover,
              );
              return t.copyWith(metadata: metadata);
            });
          })
          .expand((element) => element)
          .toList();
      ref.read(playlistsProvider.notifier).updateTracks(id, updatedTracks);
      return;
    }

    final force = ref.read(metadataSettingsProvider).forceWriteMetadata;
    final id = ref.read(playlistIdProvider).selectedId;
    final coverModel = batch
        ? ref.read(batchedTrackCoverProvider)
        : ref.read(groupedTrackCoverProvider);
    final updatedTracks = <Track>[];
    var failed = 0;
    await Future.wait(
      coverModel.map((cover) async {
        if (!cover.updated) return;
        final frontCover = cover.newCover;
        await Future.wait(
          cover.tracks.map((t) async {
            final metadata = t.metadata.nullableCopyWith(
              frontCover: () => frontCover,
            );
            if (t.properties.isCue()) {
              updatedTracks.add(t.copyWith(metadata: metadata));
              return;
            }
            try {
              await loftyWritePicture(
                file: t.path,
                picture: frontCover,
                force: force,
              );
              updatedTracks.add(t.copyWith(metadata: metadata));
            } catch (loftyError) {
              if (force) {
                failed++;
                globalTalker.error('无法强制更新封面: ${t.path}', loftyError);
                return;
              }
              try {
                await id3WritePicture(file: t.path, picture: frontCover);
                updatedTracks.add(t.copyWith(metadata: metadata));
              } catch (id3Error) {
                failed++;
                globalTalker.error('无法更新封面: ${t.path}', [loftyError, id3Error]);
              }
            }
          }),
        );
      }),
    );
    ref.read(playlistsProvider.notifier).updateTracks(id, updatedTracks);
    if (failed != 0) {
      showExceptionSnackbar(title: '错误', message: '无法更新 $failed 个文件的封面');
    }
    state = const AsyncValue.data(null);
  }
}
