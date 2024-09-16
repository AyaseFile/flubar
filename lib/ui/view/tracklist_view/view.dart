import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/constants.dart';
import 'package:flubar/ui/dialogs/cover_dialog/view.dart';
import 'package:flubar/ui/dialogs/get_dialog/providers.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/view.dart';
import 'package:flubar/ui/dialogs/properties_dialog/providers.dart';
import 'package:flubar/ui/dialogs/properties_dialog/view.dart';
import 'package:flubar/ui/dialogs/rename_dialog/view.dart';
import 'package:flubar/ui/dialogs/transcode_dialog/view.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/ui/widgets/player_widget/providers.dart';
import 'package:flubar/ui/widgets/player_widget/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/table_column_control_handles_popup_route.dart';
import 'package:material_table_view/table_view_typedefs.dart';
import 'package:super_context_menu/super_context_menu.dart';

import 'constants.dart';
import 'providers.dart';

class TrackTableView extends ConsumerStatefulWidget {
  const TrackTableView({super.key});

  @override
  ConsumerState<TrackTableView> createState() => _TrackTableViewState();
}

class _TrackTableViewState extends ConsumerState<TrackTableView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kTracklistViewPadding,
      child: Card(
        child: Padding(
          padding: kViewPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(child: _tableBuilder()),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                ),
                child: const PlayerWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcutsBuilder(Widget child) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyA, control: true):
            _SelectAllIntent(),
        SingleActivator(LogicalKeyboardKey.delete): _DeleteSelectedIntent(),
      },
      child: Actions(
        actions: {
          _SelectAllIntent: CallbackAction<_SelectAllIntent>(
            onInvoke: (_) =>
                ref.read(selectedTrackIdsProvider.notifier).handleSelectAll(),
          ),
          _DeleteSelectedIntent: CallbackAction<_DeleteSelectedIntent>(
            onInvoke: (_) =>
                ref.read(playlistsProvider.notifier).removeTracks(),
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  Widget _tableBuilder() {
    final tracks = ref.watch(tracksProvider);
    final columns = ref.read(trackTableColumnsProvider);
    return _shortcutsBuilder(GestureDetector(
      onTap: () => ref.read(selectedTrackIdsProvider.notifier).clear(),
      child: TableView.builder(
        columns: columns,
        rowHeight: kRowHeight,
        rowCount: tracks.length,
        headerBuilder: _headerBuilder,
        rowBuilder: (context, row, contentBuilder) {
          final track = tracks[row];
          return KeyedSubtree(
            key: ValueKey(track.id),
            child: ProviderScope(
              overrides: [trackItemProvider.overrideWithValue(track)],
              child: TrackRow(contentBuilder: contentBuilder),
            ),
          );
        },
      ),
    ));
  }

  Widget _headerBuilder(
      BuildContext context, TableRowContentBuilder contentBuilder) {
    const style = TextStyle(fontWeight: FontWeight.bold);
    return contentBuilder(context, (context, column) {
      final columns = ref.watch(trackTableColumnsProvider);
      final text = switch (columns[column].id) {
        kTrackNumberColumnId => '音轨',
        kTrackTitleColumnId => '标题',
        kArtistNameColumnId => '艺术家',
        kAlbumColumnId => '专辑',
        kDurationColumnId => '时长',
        _ => throw UnimplementedError(),
      };
      return InkWell(
        onTap: () => Navigator.of(context)
            .push(_createColumnControlsRoute(context, column)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: kTableTextPadding,
            child: Padding(
              padding: kCellTextPadding,
              child: Text(text, style: style, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      );
    });
  }

  ModalRoute<void> _createColumnControlsRoute(
    BuildContext cellBuildContext,
    int columnIndex,
  ) {
    final columns = ref.read(trackTableColumnsProvider);
    return TableColumnControlHandlesPopupRoute.realtime(
      controlCellBuildContext: cellBuildContext,
      columnIndex: columnIndex,
      tableViewChanged: null,
      onColumnTranslate: (index, translation) => setState(() =>
          columns[index] = columns[index].copyWith(translation: translation)),
      onColumnResize: (index, width) => setState(
          () => columns[index] = columns[index].copyWith(width: width)),
      onColumnMove: (oldIndex, newIndex) =>
          setState(() => columns.insert(newIndex, columns.removeAt(oldIndex))),
    );
  }
}

class TrackRow extends ConsumerWidget {
  final TableRowContentBuilder contentBuilder;

  const TrackRow({super.key, required this.contentBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(trackItemProvider);
    final selected = ref.watch(
        selectedTrackIdsProvider.select((state) => state.contains(track.id)));
    return ContextMenuWidget(
      child: InkWell(
        onTap: () {
          final ctrlPressed = HardwareKeyboard.instance.isControlPressed;
          final shiftPressed = HardwareKeyboard.instance.isShiftPressed;
          ref.read(selectedTrackIdsProvider.notifier).handleSelection(track.id,
              ctrlPressed: ctrlPressed, shiftPressed: shiftPressed);
        },
        child: Container(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
          child: contentBuilder(context, (context, column) {
            final columns = ref.read(trackTableColumnsProvider);
            final text = switch (columns[column].id) {
              kTrackNumberColumnId =>
                track.metadata.trackNumber?.toString() ?? '',
              kTrackTitleColumnId => track.metadata.title ?? '',
              kArtistNameColumnId => track.metadata.artist ?? '',
              kAlbumColumnId => track.metadata.album ?? '',
              kDurationColumnId =>
                CommonProperties.formatDuration(track.properties.duration),
              _ => throw UnimplementedError(),
            };
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: kTableTextPadding,
                child: Padding(
                  padding: kCellTextPadding,
                  child: Text(text, overflow: TextOverflow.ellipsis),
                ),
              ),
            );
          }),
        ),
      ),
      menuProvider: (_) => _buildContextMenu(ref, track, selected),
    );
  }

  Menu _buildContextMenu(WidgetRef ref, Track track, bool selected) {
    if (!selected) {
      ref.read(selectedTrackIdsProvider.notifier).clear();
      ref.read(selectedTrackIdsProvider.notifier).toggle(track.id);
    }
    return Menu(
      children: [
        MenuAction(
          title: '播放',
          image: MenuImage.icon(Icons.play_arrow),
          callback: () => ref.read(playerProvider.notifier).play(),
        ),
        MenuSeparator(),
        MenuAction(
          title: '编辑元数据',
          image: MenuImage.icon(Icons.edit),
          callback: () async => await ref
              .read(getDialogProvider.notifier)
              .show<void>((const Dialog(child: EditMetadataDialog()))),
        ),
        Menu(
          title: '编辑封面',
          image: MenuImage.icon(Icons.image),
          children: [
            MenuAction(
                title: '逐个编辑',
                image: MenuImage.icon(Icons.filter_1),
                callback: () async {
                  const dialog = Dialog(child: CoverDialog(isBatch: false));
                  await ref.read(getDialogProvider.notifier).show<void>(dialog);
                }),
            MenuAction(
                title: '批量编辑',
                image: MenuImage.icon(Icons.filter_none),
                attributes: MenuActionAttributes(
                  disabled: ref.read(selectedTracksProvider).length == 1,
                ),
                callback: () async {
                  const dialog = Dialog(child: CoverDialog(isBatch: true));
                  await ref.read(getDialogProvider.notifier).show<void>(dialog);
                }),
          ],
        ),
        MenuAction(
          title: '属性',
          image: MenuImage.icon(Icons.info),
          callback: () async {
            const dialog = Dialog(child: PropertiesDialog());
            await ref.read(getDialogProvider.notifier).show<void>(dialog);
          },
        ),
        MenuAction(
            title: '转码',
            image: MenuImage.icon(Icons.transit_enterexit),
            callback: () async => await ref
                .read(getDialogProvider.notifier)
                .show<void>(const TranscodeDialog(),
                    barrierDismissible: false)),
        MenuSeparator(),
        MenuAction(
            title: '重命名',
            image: MenuImage.icon(Icons.drive_file_rename_outline),
            callback: () async => await ref
                .read(getDialogProvider.notifier)
                .show<void>(const RenameDialog(), barrierDismissible: false)),
        MenuAction(
          title: '移除',
          image: MenuImage.icon(Icons.delete),
          callback: () => ref.read(playlistsProvider.notifier).removeTracks(),
        ),
      ],
    );
  }
}

final class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

final class _DeleteSelectedIntent extends Intent {
  const _DeleteSelectedIntent();
}