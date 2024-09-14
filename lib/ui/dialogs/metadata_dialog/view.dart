import 'package:flubar/models/state/common_metadata.dart';
import 'package:flubar/ui/constants.dart';
import 'package:flubar/ui/dialogs/editable_table_view/constants.dart';
import 'package:flubar/ui/dialogs/editable_table_view/providers.dart';
import 'package:flubar/ui/dialogs/editable_table_view/view.dart';
import 'package:flubar/ui/dialogs/input_dialog/view.dart';
import 'package:flubar/ui/view/tracklist_view/advanced_column.dart';
import 'package:flubar/ui/view/tracklist_view/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/table_view_typedefs.dart';
import 'package:super_context_menu/super_context_menu.dart';

import 'constants.dart';
import 'providers.dart';

class EditMetadataDialog extends ConsumerWidget {
  const EditMetadataDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(lastSelectedCommonMetadataIdProvider);
    // keep alive
    ref.watch(selectedCommonMetadataIdsProvider);
    return const _EditMetadataDialog();
  }
}

class _EditMetadataDialog extends ConsumerWidget {
  const _EditMetadataDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: kDialogWidth,
      height: kDialogHeight,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: kDoubleViewPadding,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              title: const Text('编辑元数据'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(selectedTracksProvider.notifier)
                        .updateMetadata();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  autofocus: true,
                  child: const Text('保存'),
                ),
              ],
            ),
            body: const MetadataTableView(),
          ),
        ),
      ),
    );
  }
}

class MetadataTableView extends ConsumerWidget {
  const MetadataTableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: kViewPadding,
        child: GestureDetector(
          onTap: () =>
              ref.read(selectedCommonMetadataIdsProvider.notifier).clear(),
          child: _tableBuilder(ref),
        ),
      ),
    );
  }

  Widget _tableBuilder(WidgetRef ref) {
    final allMetadata = ref.watch(commonMetadataProvider);
    return TableView.builder(
      columns: kMetadataColumns,
      rowHeight: kRowHeight,
      rowCount: allMetadata.length,
      headerBuilder: _headerBuilder,
      rowBuilder: (context, row, contentBuilder) {
        final metadata = allMetadata[row];
        return KeyedSubtree(
          key: ValueKey(metadata.id),
          child: ProviderScope(
            overrides: [commonMetadataItemProvider.overrideWithValue(metadata)],
            child: MetadataRow(contentBuilder: contentBuilder),
          ),
        );
      },
    );
  }

  Widget _headerBuilder(
      BuildContext context, TableRowContentBuilder contentBuilder) {
    const style = TextStyle(fontWeight: FontWeight.bold);
    return contentBuilder(context, (context, column) {
      final text = switch (column) {
        kKeyColumnIndex => '键',
        kValueColumnIndex => '值',
        _ => throw UnimplementedError(),
      };
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: kTableTextPadding,
          child: Padding(
            padding: kCellTextPadding,
            child: Text(text, style: style, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    });
  }
}

class MetadataRow extends ConsumerWidget {
  final TableRowContentBuilder contentBuilder;

  const MetadataRow({super.key, required this.contentBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = ref.watch(commonMetadataItemProvider);
    final selected = ref.watch(selectedCommonMetadataIdsProvider
        .select((state) => state.contains(metadata.id)));
    return ContextMenuWidget(
        child: InkWell(
          onTap: () {
            final ctrlPressed = HardwareKeyboard.instance.isControlPressed;
            final shiftPressed = HardwareKeyboard.instance.isShiftPressed;
            ref
                .read(selectedCommonMetadataIdsProvider.notifier)
                .handleSelection(metadata.id,
                    ctrlPressed: ctrlPressed, shiftPressed: shiftPressed);
          },
          child: Container(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Colors.transparent,
            child: contentBuilder(context, (context, column) {
              final text = switch (column) {
                kKeyColumnIndex => metadata.key,
                kValueColumnIndex => metadata.value,
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
        menuProvider: (_) => _buildContextMenu(ref, metadata, selected));
  }

  Menu _buildContextMenu(
      WidgetRef ref, CommonMetadataModel metadata, bool selected) {
    if (!selected) {
      ref.read(selectedCommonMetadataIdsProvider.notifier).clear();
      ref.read(selectedCommonMetadataIdsProvider.notifier).toggle(metadata.id);
    }
    final length = ref.read(selectedCommonMetadataIdsProvider).length;
    return Menu(
      children: [
        if (length == 1) // 如果值选中一个元数据
          MenuAction(
            title: metadata.multi || (metadata.value.isEmpty && !metadata.multi)
                ? '批量编辑'
                : '编辑', // 元数据是否多值, 或为空, 则显示批量编辑
            image: MenuImage.icon(Icons.edit),
            callback: () => Get.dialog(InputDialog(
              dialogTitle: '编辑 ${metadata.key}',
              initialValue: metadata.value,
              onConfirm: (value) => ref
                  .read(commonMetadataProvider.notifier)
                  .updateCommonValue(value),
            )),
          ),
        if ((length == 1 && metadata.multi ||
                (metadata.value.isEmpty && !metadata.multi)) ||
            length > 1) // 同时是多值, 或为空; 或选中多个元数据, 允许在表格中编辑
          MenuAction(
            title: '表格编辑',
            image: MenuImage.icon(Icons.table_view),
            callback: () {
              final ids = ref.read(selectedCommonMetadataIdsProvider);
              final length = ids.length + 1; // 加上文件名列
              var columnWidth = kEditableTableColumnWidth;
              final currentWidth = Get.width;
              // 计算列宽度
              final calcWidth = currentWidth / length;
              if (calcWidth < kEditableTableColumnWidth) {
                columnWidth = kEditableTableColumnWidth;
              } else if (calcWidth > kEditableTableColumnWidth) {
                columnWidth = calcWidth;
              }
              final columns = [
                AdvancedColumn(id: kFileNameColumnId, width: columnWidth)
              ];
              for (final id in ids) {
                final columnId = switch (id) {
                  kTrackTitleRowId => kTrackTitleColumnId,
                  kArtistNameRowId => kArtistNameColumnId,
                  kAlbumRowId => kAlbumColumnId,
                  kAlbumArtistRowId => kAlbumArtistColumnId,
                  kTrackNumberRowId => kTrackNumberColumnId,
                  kTrackTotalRowId => kTrackTotalColumnId,
                  kDiscNumberRowId => kDiscNumberColumnId,
                  kDiscTotalRowId => kDiscTotalColumnId,
                  kDateRowId => kDateColumnId,
                  kGenreRowId => kGenreColumnId,
                  _ => throw UnimplementedError(),
                };
                columns.add(AdvancedColumn(id: columnId, width: columnWidth));
              }
              Get.dialog(ProviderScope(
                overrides: [
                  editableTableColumnsProvider.overrideWithValue(columns)
                ],
                child: const EditableTableDialog(),
              ));
            },
          ),
        MenuAction(
          title: '清除',
          image: MenuImage.icon(Icons.delete),
          callback: () =>
              ref.read(commonMetadataProvider.notifier).removeCommonValue(),
        )
      ],
    );
  }
}
