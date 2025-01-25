import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:riverpod/riverpod.dart';
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
