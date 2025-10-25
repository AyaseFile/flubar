import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/dialogs/ratio_dialog/view.dart';
import 'package:flubar/utils/backup/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'providers.dart';

class MetadataMatchingDialog extends ConsumerWidget {
  const MetadataMatchingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(metadataBackupProvider);
    return _MetadataMatchingDialog();
  }
}

class _MetadataMatchingDialog extends StatelessWidget {
  const _MetadataMatchingDialog();

  @override
  Widget build(BuildContext context) {
    return RatioAlertDialog(
      title: const Text('匹配元数据'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_StatusRow(), const SizedBox(height: 16), _MatchingList()],
      ),
      actions: [
        _SequentialMatchButton(),
        _RematchButton(),
        _ClearButton(),
        _CancelButton(),
        _ApplyButton(),
      ],
    );
  }
}

class _StatusRow extends ConsumerWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackLength = ref.read(
      selectedTracksProvider.select((state) => state.length),
    );
    final backupLength = ref.read(
      metadataBackupProvider.select((state) => state.metadataList.length),
    );

    return Row(
      children: [
        Text('当前: $trackLength 条音轨'),
        const SizedBox(width: 16),
        Text('备份: $backupLength 个元数据'),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer(
              builder: (context, ref, _) {
                final matchCount = ref.watch(
                  matchUtilProvider.select(
                    (state) => state.result.matches.length,
                  ),
                );
                return Text('已匹配: $matchCount');
              },
            ),
            const SizedBox(width: 16),
            Consumer(
              builder: (context, ref, _) {
                final conflictCount = ref.watch(
                  matchUtilProvider.select(
                    (state) => state.result.conflicts.length,
                  ),
                );
                return Text(
                  '冲突: $conflictCount',
                  style: TextStyle(
                    color: conflictCount > 0 ? Colors.orange : null,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Consumer(
              builder: (context, ref, _) {
                final matchCount = ref.watch(
                  matchUtilProvider.select(
                    (state) => state.result.matches.length,
                  ),
                );
                return Text('已使用: $matchCount/$backupLength');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchingList extends ConsumerWidget {
  const _MatchingList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTracks = ref.watch(selectedTracksProvider);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: selectedTracks.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            ProviderScope(
              overrides: [matchingItemProvider.overrideWithValue(index)],
              child: const _MatchingItem(),
            ),
            if (index < selectedTracks.length - 1) const Divider(),
          ],
        );
      },
    );
  }
}

class _MatchingItem extends ConsumerWidget {
  const _MatchingItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.read(matchingItemProvider);
    final selectedTracks = ref.read(selectedTracksProvider);
    final track = selectedTracks[index];
    final trackFilename = p.basename(track.path);
    final trackInfo =
        '${track.metadata.artist ?? '未知艺术家'} - ${track.metadata.title ?? '未知音轨'}';

    return Row(
      children: [
        Consumer(
          builder: (context, ref, _) {
            final conflicted = ref.watch(
              matchUtilProvider.select(
                (state) => state.result.conflicts.contains(index),
              ),
            );
            final match = ref.watch(
              matchUtilProvider.select((state) => state.result.matches[index]),
            );
            return _buildStatusIcon(match, conflicted);
          },
        ),
        const SizedBox(width: 12),
        _buildTrackInfo(trackFilename, trackInfo),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.arrow_forward),
        ),
        Expanded(flex: 2, child: const _MatchDropdown()),
      ],
    );
  }

  Widget _buildStatusIcon(int? match, bool conflicted) {
    return Icon(
      match != null
          ? Icons.check_circle
          : conflicted
          ? Icons.warning
          : Icons.cancel,
      color: match != null
          ? Colors.green
          : conflicted
          ? Colors.orange
          : Colors.red,
    );
  }

  Widget _buildTrackInfo(String filename, String info) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(filename, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(info, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MatchDropdown extends ConsumerWidget {
  const _MatchDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.read(matchingItemProvider);
    final backup = ref.read(metadataBackupProvider);

    return Consumer(
      builder: (context, ref, _) {
        final maches = ref.watch(
          matchUtilProvider.select((state) => state.result.matches),
        );
        final match = maches[index];
        final conflicted = ref.watch(
          matchUtilProvider.select(
            (state) => state.result.conflicts.contains(index),
          ),
        );
        final opts = [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('(跳过)', style: TextStyle(color: Colors.grey)),
          ),
          ...backup.metadataList.asMap().entries.map((e) {
            final backupIndex = e.key;
            final metadata = e.value;
            final used = maches.values.contains(backupIndex);
            final currentMatch = match == backupIndex;
            final text =
                '${p.basename(metadata.path)} - ${metadata.metadata['title'] ?? '未知音轨'}';

            return DropdownMenuItem<int?>(
              value: backupIndex,
              child: Row(
                children: [
                  if (used)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: currentMatch ? Colors.green : Colors.grey,
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: used && !currentMatch ? Colors.grey : null,
                        fontWeight: currentMatch ? FontWeight.bold : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ];

        return DropdownButtonFormField<int?>(
          initialValue: match,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: match != null && !conflicted
                    ? Colors.green.withValues(alpha: 0.3)
                    : conflicted
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: match != null && !conflicted
                    ? Colors.green.withValues(alpha: 0.3)
                    : conflicted
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: match != null && !conflicted
                    ? Colors.green
                    : conflicted
                    ? Colors.orange
                    : Colors.grey,
                width: 2,
              ),
            ),
            fillColor: match != null && !conflicted
                ? Colors.green.withValues(alpha: 0.1)
                : conflicted
                ? Colors.orange.withValues(alpha: 0.1)
                : null,
            filled: match != null || conflicted,
          ),
          hint: const Text('选择备份'),
          isExpanded: true,
          items: opts,
          onChanged: (value) {
            ref.read(matchUtilProvider.notifier).updateMatch(index, value);
          },
        );
      },
    );
  }
}

class _SequentialMatchButton extends ConsumerWidget {
  const _SequentialMatchButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackLength = ref.watch(
      selectedTracksProvider.select((state) => state.length),
    );
    final backupLength = ref.watch(
      metadataBackupProvider.select((state) => state.metadataList.length),
    );
    return TextButton(
      onPressed: trackLength == backupLength
          ? () => ref.read(matchUtilProvider.notifier).sequentialMatch()
          : null,
      child: const Text('按顺序匹配'),
    );
  }
}

class _RematchButton extends ConsumerWidget {
  const _RematchButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(matchUtilProvider.notifier).match(),
      child: const Text('重新匹配'),
    );
  }
}

class _ClearButton extends ConsumerWidget {
  const _ClearButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchCount = ref.watch(
      matchUtilProvider.select((state) => state.result.matches.length),
    );
    return TextButton(
      onPressed: matchCount > 0
          ? () => ref.read(matchUtilProvider.notifier).clear()
          : null,
      child: const Text('清除'),
    );
  }
}

class _CancelButton extends ConsumerWidget {
  const _CancelButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('取消'),
    );
  }
}

class _ApplyButton extends ConsumerWidget {
  const _ApplyButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backup = ref.read(metadataBackupProvider);
    final matchCount = ref.watch(
      matchUtilProvider.select((state) => state.result.matches.length),
    );

    return TextButton(
      onPressed: matchCount > 0
          ? () async {
              try {
                final matchState = ref.read(matchUtilProvider);
                await ref
                    .read(matchUtilProvider.notifier)
                    .apply(matchState.result, backup);
                if (context.mounted) Navigator.of(context).pop();
              } catch (_) {}
            }
          : null,
      autofocus: true,
      child: const Text('应用元数据匹配'),
    );
  }
}
