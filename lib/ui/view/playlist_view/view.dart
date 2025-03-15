import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/models/state/playlist.dart';
import 'package:flubar/ui/constants.dart';
import 'package:flubar/ui/dialogs/get_dialog/providers.dart';
import 'package:flubar/ui/dialogs/input_dialog/view.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_context_menu/super_context_menu.dart';

import 'constants.dart';
import 'providers.dart';

class PlaylistView extends StatelessWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPlaylistViewPadding,
      child: const PlaylistCardList(),
    );
  }
}

class PlaylistCardList extends ConsumerWidget {
  const PlaylistCardList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return ContextMenuWidget(
        menuProvider: (_) => _buildContextMenu(ref),
        child: ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return ProviderScope(
              overrides: [playlistItemProvider.overrideWithValue(playlist)],
              child: const PlaylistCard(),
            );
          },
        ));
  }

  Menu _buildContextMenu(WidgetRef ref) {
    return Menu(children: [
      MenuAction(
        title: '添加播放列表',
        image: MenuImage.icon(Icons.add),
        callback: () async {
          await ref.read(getDialogProvider.notifier).show(
                InputDialog(
                  dialogTitle: '添加播放列表',
                  onConfirm: (name) {
                    final id = ref.read(playlistIdProvider.notifier).nextId();
                    ref.read(playlistsProvider.notifier).addPlaylists([
                      Playlist(id: id, name: name, tracks: const IList.empty()),
                    ]);
                  },
                ),
              );
        },
      )
    ]);
  }
}

class PlaylistCard extends ConsumerWidget {
  const PlaylistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistItemProvider);
    final selected = ref.watch(
        playlistIdProvider.select((state) => state.selectedId == playlist.id));
    return ContextMenuWidget(
        menuProvider: (_) => _buildContextMenu(ref, playlist),
        child: Card(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
              : null,
          child: ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(playlist.name, overflow: TextOverflow.ellipsis),
            onTap: () {
              if (!selected) {
                ref.read(selectedTrackIdsProvider.notifier).clear();
              }
              ref.read(playlistIdProvider.notifier).select(playlist.id);
            },
          ),
        ));
  }

  Menu _buildContextMenu(WidgetRef ref, Playlist playlist) {
    return Menu(children: [
      if (playlist.id != kDefaultPlaylistId) // 不允许删除默认播放列表
        MenuAction(
          title: '删除',
          image: MenuImage.icon(Icons.delete),
          callback: () =>
              ref.read(playlistsProvider.notifier).removePlaylist(playlist),
        ),
      MenuAction(
        title: '重命名',
        image: MenuImage.icon(Icons.edit),
        callback: () async {
          await ref.read(getDialogProvider.notifier).show(
                InputDialog(
                  dialogTitle: '重命名',
                  initialValue: playlist.name,
                  onConfirm: (name) => ref
                      .read(playlistsProvider.notifier)
                      .updatePlaylist(playlist.copyWith(name: name)),
                ),
              );
        },
      ),
    ]);
  }
}
