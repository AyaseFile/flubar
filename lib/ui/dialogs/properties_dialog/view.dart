import 'package:flubar/ui/constants.dart';
import 'package:flubar/ui/dialogs/fixed_size_dialog/view.dart';
import 'package:flubar/ui/view/tracklist_view/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/table_view_typedefs.dart';

import 'constants.dart';
import 'providers.dart';

class PropertiesDialog extends StatelessWidget {
  const PropertiesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return FixedSizeDialog(
      width: kDialogWidth,
      height: kDialogHeight,
      child: Padding(
        padding: kDoubleViewPadding,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('属性'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('退出'),
              ),
            ],
          ),
          body: const _PropertiesTableView(),
        ),
      ),
    );
  }
}

class _PropertiesTableView extends ConsumerWidget {
  const _PropertiesTableView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: kViewPadding, child: _tableBuilder(ref)),
    );
  }

  Widget _tableBuilder(WidgetRef ref) {
    final allProperties = ref.watch(commonPropertiesProvider);
    return TableView.builder(
      style: TableViewStyle(
        scrollbars: TableViewScrollbarsStyle(
            vertical: TableViewScrollbarStyle(scrollPadding: false)),
      ),
      columns: kPropertiesColumns,
      rowHeight: kRowHeight,
      rowCount: allProperties.length,
      headerBuilder: _headerBuilder,
      rowBuilder: (context, row, contentBuilder) {
        final metadata = allProperties[row];
        return KeyedSubtree(
          key: ValueKey(metadata.id),
          child: ProviderScope(
            overrides: [
              commonPropertiesItemProvider.overrideWithValue(metadata)
            ],
            child: PropertiesRow(contentBuilder: contentBuilder),
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

class PropertiesRow extends ConsumerWidget {
  final TableRowContentBuilder contentBuilder;

  const PropertiesRow({super.key, required this.contentBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = ref.watch(commonPropertiesItemProvider);
    return contentBuilder(context, (context, column) {
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
            child: TooltipTheme(
              data: kTooltipTheme,
              child: Tooltip(
                message: text,
                waitDuration: kWaitDuration,
                preferBelow: true,
                child: Text(text, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
      );
    });
  }
}
