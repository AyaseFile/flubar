import 'package:flubar/app/talker.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/extensions/properties_extension.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/rust/api/lofty.dart' as lofty;
import 'package:flubar/ui/dialogs/cover_dialog/providers.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class MetadataApplyUtil extends _$MetadataApplyUtil {
  @override
  void build() {}

  Future<bool> applyMetadata() async {
    final id = ref.read(playlistIdProvider).selectedId;
    final selectedTracks = ref.read(selectedTracksProvider);
    final updatedTracks = selectedTracks.map(
      (t) => t.copyWith(pendingWriteback: true),
    );
    ref.read(playlistsProvider.notifier).updateTracks(id, updatedTracks);
    return true;
  }

  Future<void> applyCover({required bool batch}) async {
    final id = ref.read(playlistIdProvider).selectedId;
    final coverModel = batch
        ? ref.read(batchedTrackCoverProvider)
        : ref.read(groupedTrackCoverProvider);
    final updatedTracks = coverModel
        .map((cover) {
          if (!cover.updated) return const <Track>[];
          final frontCover = cover.newCover;
          return cover.tracks.map((t) {
            final metadata = t.metadata.nullableCopyWith(
              frontCover: () => frontCover,
            );
            return t.copyWith(metadata: metadata, pendingWriteback: true);
          });
        })
        .expand((element) => element)
        .toList();
    if (updatedTracks.isNotEmpty) {
      ref.read(playlistsProvider.notifier).updateTracks(id, updatedTracks);
    }
  }
}

@Riverpod(keepAlive: true)
class MetadataWritebackUtil extends _$MetadataWritebackUtil {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> writebackSelected() => _writebackSelected(force: false);

  Future<bool> writebackSelectedForce() => _writebackSelected(force: true);

  Future<bool> _writebackSelected({required bool force}) async {
    state = const AsyncValue.loading();

    final id = ref.read(playlistIdProvider).selectedId;
    final selectedTracks = ref.read(selectedTracksProvider);
    final pendingTracks = selectedTracks
        .where((t) => t.pendingWriteback)
        .toList();
    if (pendingTracks.isEmpty) {
      state = const AsyncValue.data(null);
      return true;
    }

    var failed = 0;
    final results = await Future.wait(
      pendingTracks.map((track) async {
        if (track.properties.isCue()) {
          return track.copyWith(pendingWriteback: false);
        }
        try {
          await lofty.writeMetadata(
            metadata: track.metadata,
            file: track.path,
            force: force,
            writeTags: true,
            writeCover: true,
          );
          return track.copyWith(pendingWriteback: false);
        } catch (e, st) {
          failed++;
          globalTalker.error('写回元数据失败: ${track.path}', e, st);
          return track;
        }
      }),
    );

    ref.read(playlistsProvider.notifier).updateTracks(id, results);

    state = const AsyncValue.data(null);
    if (failed != 0) {
      showExceptionSnackbar(title: '错误', message: '无法写回 $failed 个文件的元数据');
      return false;
    }

    final successCount = results
        .where((track) => !track.pendingWriteback)
        .length;
    if (successCount > 0) {
      globalTalker.info('成功写回 $successCount 个文件的元数据');
    }
    return true;
  }
}
