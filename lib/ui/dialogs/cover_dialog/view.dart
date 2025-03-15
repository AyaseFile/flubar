import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/state/track_cover.dart';
import 'package:flubar/ui/constants.dart';
import 'package:flubar/ui/dialogs/fixed_size_dialog/view.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/view.dart';
import 'package:flubar/ui/widgets/cover_drag_widget/view.dart';
import 'package:flubar/utils/metadata/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'constants.dart';
import 'providers.dart';

class CoverDialog extends ConsumerWidget {
  final bool isBatch;

  const CoverDialog({super.key, required this.isBatch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCovers = isBatch
        ? ref.watch(batchedTrackCoverProvider)
        : ref.watch(groupedTrackCoverProvider);
    final coverIndex = ref.watch(currentTrackCoverIndexProvider);

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
            title: const Text('编辑封面'),
            actions: [
              IconButton(
                onPressed: coverIndex > 0
                    ? () => ref
                        .read(currentTrackCoverIndexProvider.notifier)
                        .previous()
                    : null,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: coverIndex < selectedCovers.length - 1
                    ? () =>
                        ref.read(currentTrackCoverIndexProvider.notifier).next()
                    : null,
                icon: const Icon(Icons.arrow_forward),
              ),
              const SizedBox(width: 8),
              const _CoverSettingsIconButton(),
              const SizedBox(width: 8),
              TextButton(
                onPressed: !ref.watch(metadataUtilProvider).isLoading
                    ? () => Navigator.of(context).pop()
                    : null,
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ref.watch(metadataUtilProvider).isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(),
                      ))
                  : TextButton(
                      onPressed: () async {
                        await ref
                            .read(metadataUtilProvider.notifier)
                            .writeCover(isBatch);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      autofocus: true,
                      child: const Text('保存'),
                    ),
            ],
          ),
          body: _buildBody(selectedCovers[coverIndex], ref),
        ),
      ),
    );
  }

  Widget _buildBody(TrackCoverModel trackCover, WidgetRef ref) {
    Widget buildImage() {
      return AspectRatio(
        aspectRatio: 1,
        child: Padding(
            padding: kViewPadding,
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: switch (trackCover) {
                  TrackCoverModel(updated: false, oldCover: final cover?) ||
                  TrackCoverModel(updated: true, newCover: final cover?) =>
                    Image.memory(
                      cover,
                      fit: BoxFit.cover,
                    ),
                  _ => const Center(
                      child: Icon(Icons.image_not_supported, size: 72)),
                },
              ),
              const CoverDragWidget()
            ])),
      );
    }

    Widget buildButtons() {
      final notifier = isBatch
          ? ref.read(batchedTrackCoverProvider.notifier)
          : ref.read(groupedTrackCoverProvider.notifier);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: trackCover.updated ? () => notifier.useOldCover() : null,
            tooltip: '使用原封面',
            icon: const Icon(Icons.undo),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: !trackCover.updated && trackCover.newCover != null
                ? () => notifier.useNewCover()
                : null,
            tooltip: '使用新封面',
            icon: const Icon(Icons.redo),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: trackCover.updated && trackCover.newCover == null
                ? null
                : () => notifier.removeCover(),
            tooltip: '移除封面',
            icon: const Icon(Icons.delete),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildImage(),
              const SizedBox(height: 16),
              buildButtons(),
            ],
          )),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ListView.builder(
            itemCount: trackCover.tracks.length,
            itemBuilder: (context, index) {
              final track = trackCover.tracks[index];
              return Card(
                child: ListTile(
                  title: Text(
                    p.basename(track.path),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    _formatSubtitle(
                        track.metadata.artist, track.metadata.title),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatSubtitle(String? artist, String? title) {
    if (artist != null && title != null) {
      return '$artist - $title';
    } else if (artist != null) {
      return '$artist - 未知音轨';
    } else if (title != null) {
      return '未知艺术家 - $title';
    } else {
      return '未知';
    }
  }
}

class _CoverSettingsIconButton extends ConsumerWidget {
  const _CoverSettingsIconButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(builder: (context) {
      return IconButton(
        icon: const Icon(Icons.settings),
        onPressed: !ref.watch(metadataUtilProvider).isLoading
            ? () {
                MetadataSettingsIconButton.showSettingsPopupMenu(
                  context: context,
                  children: [
                    ListTile(
                      title: const Text('仅写入内存'),
                      trailing: Consumer(builder: (context, ref, _) {
                        final writeToMemory = ref.watch(metadataSettingsProvider
                            .select((state) => state.writeToMemoryOnly));
                        return Checkbox(
                          value: writeToMemory,
                          onChanged: (value) => ref
                              .read(metadataSettingsProvider.notifier)
                              .updateWriteToMemoryOnly(value!),
                        );
                      }),
                    ),
                    ListTile(
                      title: const Text('强制写入元数据'),
                      trailing: Consumer(builder: (context, ref, _) {
                        final force = ref.watch(metadataSettingsProvider
                            .select((state) => state.forceWriteMetadata));
                        return Checkbox(
                          value: force,
                          onChanged: (value) => ref
                              .read(metadataSettingsProvider.notifier)
                              .updateForceWriteMetadata(value!),
                        );
                      }),
                    ),
                  ].map((e) => PopupMenuItem(child: e)).toList(),
                );
              }
            : null,
      );
    });
  }
}
