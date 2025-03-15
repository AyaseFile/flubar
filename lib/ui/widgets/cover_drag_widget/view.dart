import 'package:flubar/models/extensions/data_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'providers.dart';

class CoverDragWidget extends ConsumerWidget {
  const CoverDragWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            minHeight: constraints.maxHeight,
          ),
          child: DropRegion(
              hitTestBehavior: HitTestBehavior.translucent,
              formats: [Formats.fileUri],
              onDropOver: (event) =>
                  event.session.allowedOperations.contains(DropOperation.copy)
                      ? DropOperation.copy
                      : DropOperation.none,
              onPerformDrop: (event) async {
                final items = event.session.items;
                if (items.length == 1) {
                  ref.read(coverDragStateProvider.notifier).setDragging(false);
                  final uri =
                      await items.first.dataReader!.readValue(Formats.fileUri);
                  if (uri == null) return;
                  await ref
                      .read(coverDragStateProvider.notifier)
                      .addFile(uri.toFilePath());
                }
              },
              onDropEnter: (_) =>
                  ref.read(coverDragStateProvider.notifier).setDragging(true),
              onDropLeave: (_) =>
                  ref.read(coverDragStateProvider.notifier).setDragging(false),
              child: _DragIndicator()),
        );
      },
    );
  }
}

class _DragIndicator extends ConsumerWidget {
  const _DragIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragState = ref.watch(coverDragStateProvider);
    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dragState ? 1.0 : 0.0,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_upload, size: 96),
            SizedBox(height: 16),
            Text(
              '单张图片',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
