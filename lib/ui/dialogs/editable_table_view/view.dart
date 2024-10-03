import 'package:flubar/ui/constants.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/dialogs/ratio_dialog/view.dart';
import 'package:flubar/ui/view/tracklist_view/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/table_column_control_handles_popup_route.dart';
import 'package:material_table_view/table_view_typedefs.dart';
import 'package:path/path.dart' as p;

import 'constants.dart';
import 'providers.dart';

class EditableTableDialog extends StatelessWidget {
  const EditableTableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return RatioDialog(
      child: Padding(
        padding: kDoubleViewPadding,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('表格编辑'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  autofocus: true,
                  child: const Text('完成')),
            ],
          ),
          body: const EditableTableView(),
        ),
      ),
    );
  }
}

class EditableTableView extends ConsumerStatefulWidget {
  const EditableTableView({super.key});

  @override
  ConsumerState<EditableTableView> createState() => _EditableTableViewState();
}

class _EditableTableViewState extends ConsumerState<EditableTableView> {
  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: kViewPadding,
          child: _tableBuilder(),
        ));
  }

  Widget _tableBuilder() {
    final selectedTracks = ref.watch(selectedTracksProvider);
    final columns = ref.read(editableTableColumnsProvider);
    return TableView.builder(
      columns: columns,
      rowHeight: kEditableTableRowHeight,
      rowCount: selectedTracks.length,
      headerBuilder: _headerBuilder,
      rowBuilder: (context, row, contentBuilder) {
        final track = selectedTracks[row];
        return KeyedSubtree(
          key: ValueKey(track.id),
          child: ProviderScope(
            overrides: [editableTrackItemProvider.overrideWithValue(track)],
            child: EditableTrackRow(contentBuilder: contentBuilder),
          ),
        );
      },
    );
  }

  Widget _headerBuilder(
      BuildContext context, TableRowContentBuilder contentBuilder) {
    const style = TextStyle(fontWeight: FontWeight.bold);
    return contentBuilder(context, (context, column) {
      final columns = ref.watch(editableTableColumnsProvider);
      final text = switch (columns[column].id) {
        kTrackNumberColumnId => '音轨',
        kTrackTitleColumnId => '标题',
        kArtistNameColumnId => '艺术家',
        kAlbumColumnId => '专辑',
        // kDurationColumnId => '时长',
        kAlbumArtistColumnId => '专辑艺术家',
        kTrackTotalColumnId => '音轨总数',
        kDiscNumberColumnId => '碟片',
        kDiscTotalColumnId => '碟片总数',
        kDateColumnId => '日期',
        kGenreColumnId => '流派',
        kFileNameColumnId => '文件名',
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
    final columns = ref.read(editableTableColumnsProvider);
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

class EditableTrackRow extends ConsumerWidget {
  final TableRowContentBuilder contentBuilder;

  const EditableTrackRow({super.key, required this.contentBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(editableTrackItemProvider);
    return contentBuilder(context, (context, column) {
      final columns = ref.read(editableTableColumnsProvider);
      final text = switch (columns[column].id) {
        kTrackNumberColumnId => track.metadata.trackNumber?.toString() ?? '',
        kTrackTitleColumnId => track.metadata.title ?? '',
        kArtistNameColumnId => track.metadata.artist ?? '',
        kAlbumColumnId => track.metadata.album ?? '',
        kAlbumArtistColumnId => track.metadata.albumArtist ?? '',
        kTrackTotalColumnId => track.metadata.trackTotal?.toString() ?? '',
        kDiscNumberColumnId => track.metadata.discNumber?.toString() ?? '',
        kDiscTotalColumnId => track.metadata.discTotal?.toString() ?? '',
        kDateColumnId => track.metadata.date?.toString() ?? '',
        kGenreColumnId => track.metadata.genre ?? '',
        kFileNameColumnId => p.basename(track.path),
        _ => throw UnimplementedError(),
      };
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: kTableTextPadding,
          child: Padding(
              padding: kCellTextPadding,
              child: TextFieldCell(
                enabled: columns[column].id != kFileNameColumnId,
                text: text,
                onSubmitted: columns[column].id == kFileNameColumnId
                    ? null
                    : (text) => ref
                        .read(selectedTracksProvider.notifier)
                        .updateMetadataState(
                          trackId: track.id,
                          columnId: columns[column].id,
                          value: text,
                        ),
              )),
        ),
      );
    });
  }
}

class TextFieldCell extends HookWidget {
  final bool enabled;
  final String text;
  final void Function(String)? onSubmitted;

  const TextFieldCell({
    super.key,
    required this.enabled,
    required this.text,
    this.onSubmitted,
  }) : assert((enabled && onSubmitted != null) ||
            (!enabled && onSubmitted == null));

  @override
  Widget build(BuildContext context) {
    final textStyle = Get.textTheme.bodyMedium?.copyWith(
      color: enabled ? null : Theme.of(context).disabledColor,
    );

    if (!enabled) {
      return Text(text,
          style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final ctrl = useTextEditingController(text: text);
    final focusNode = useFocusNode();

    useEffect(() {
      void listener() {
        if (!focusNode.hasFocus) {
          onSubmitted!.call(ctrl.text);
        }
      }

      focusNode.addListener(listener);
      return () {
        focusNode.removeListener(listener);
      };
    }, [focusNode]);

    return TextField(
      controller: ctrl,
      focusNode: focusNode,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
      ),
      style: textStyle,
      maxLines: 1,
    );
  }
}
