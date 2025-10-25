import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:flubar/utils/metadata/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
bool hasTrack(Ref ref) {
  return ref.watch(currentPlaylistProvider).tracks.isNotEmpty;
}

@Riverpod(keepAlive: true)
bool hasSelection(Ref ref) {
  return ref.watch(selectedTrackIdsProvider).isNotEmpty;
}

@Riverpod(keepAlive: true)
bool hasPendingWritebackSelection(Ref ref) {
  final selectedTracks = ref.watch(selectedTracksProvider);
  return selectedTracks.any((track) => track.pendingWriteback);
}

@riverpod
bool canWritebackSelection(Ref ref) {
  final hasPending = ref.watch(hasPendingWritebackSelectionProvider);
  final isLoading = ref.watch(metadataWritebackUtilProvider).isLoading;
  return hasPending && !isLoading;
}
