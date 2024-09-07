import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class CoverDragWidget extends ConsumerWidget {
  const CoverDragWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragState = ref.watch(coverDragStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            minHeight: constraints.maxHeight,
          ),
          child: DropTarget(
            onDragDone: (detail) async {
              if (detail.files.length == 1) {
                await ref
                    .read(coverDragStateProvider.notifier)
                    .addFile(detail.files.first);
              }
            },
            onDragEntered: (_) =>
                ref.read(coverDragStateProvider.notifier).setDragging(true),
            onDragExited: (_) =>
                ref.read(coverDragStateProvider.notifier).setDragging(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Center(
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
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
