import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class MediaDragWidget extends ConsumerWidget {
  const MediaDragWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragState = ref.watch(mediaDragStateProvider);
    final enableDrag = ref.watch(enableMediaDragProvider);

    return IgnorePointer(child: LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            minHeight: constraints.maxHeight,
          ),
          child: DropTarget(
            onDragDone: (detail) async => enableDrag
                ? await ref
                    .read(mediaDragStateProvider.notifier)
                    .addFiles(detail.files)
                : null,
            onDragEntered: (_) => enableDrag
                ? ref.read(mediaDragStateProvider.notifier).setDragging(true)
                : null,
            onDragExited: (_) => enableDrag
                ? ref.read(mediaDragStateProvider.notifier).setDragging(false)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: dragState ? 1.0 : 0.0,
                  child: const Icon(Icons.file_upload, size: 96),
                ),
              ),
            ),
          ),
        );
      },
    ));
  }
}
