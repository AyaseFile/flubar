import 'package:flubar/models/extensions/data_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'providers.dart';

class MediaDragWidget extends ConsumerWidget {
  const MediaDragWidget({super.key});

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
                final enableDrag = ref.read(enableMediaDragProvider);
                if (!enableDrag) return;
                final paths = await _getPaths(event);
                await ref.read(mediaDragStateProvider.notifier).addFiles(paths);
              },
              onDropEnter: (_) {
                final enableDrag = ref.read(enableMediaDragProvider);
                if (!enableDrag) return;
                ref.read(mediaDragStateProvider.notifier).setDragging(true);
              },
              onDropLeave: (_) {
                final enableDrag = ref.read(enableMediaDragProvider);
                if (!enableDrag) return;
                ref.read(mediaDragStateProvider.notifier).setDragging(false);
              },
              child: const _DragIndicator()),
        );
      },
    );
  }

  Future<Iterable<String>> _getPaths(PerformDropEvent event) async {
    final items = event.session.items;
    final paths = (await Future.wait(
            items.map((e) => e.dataReader!.readValue(Formats.fileUri))))
        .nonNulls
        .map((e) => e.toFilePath());
    return paths;
  }
}

class _DragIndicator extends ConsumerWidget {
  const _DragIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragState = ref.watch(mediaDragStateProvider);
    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dragState ? 1.0 : 0.0,
        child: const IgnorePointer(child: Icon(Icons.file_upload, size: 96)),
      ),
    );
  }
}
