import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class PlayerWidget extends ConsumerWidget {
  const PlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(playerProvider); // 保证播放器已经初始化
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [_PlaybackControls(), _ProgressSlider()],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _TrackMetadataWidget()),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PreviousButton(),
                  _PlayPauseButton(),
                  _StopButton(),
                  _NextButton(),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}

class _TrackMetadataWidget extends ConsumerWidget {
  const _TrackMetadataWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerTrackMetadataProvider).value;
    return track != null
        ? Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              '${track.artist ?? '未知艺术家'} - ${track.title ?? '未知音轨'}',
              overflow: TextOverflow.ellipsis,
            ),
          )
        : const SizedBox();
  }
}

class _PreviousButton extends ConsumerWidget {
  const _PreviousButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPrevious = ref.watch(playerHasPreviousProvider).value ?? false;
    return IconButton(
      icon: const Icon(Icons.skip_previous),
      onPressed: hasPrevious
          ? () async => await ref.read(playerProvider.notifier).previous()
          : null,
    );
  }
}

class _PlayPauseButton extends ConsumerWidget {
  const _PlayPauseButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerPlayingProvider).value ?? false;
    final hasTrack = ref.watch(playerHasTrackProvider).value ?? false;
    return IconButton(
      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
      onPressed: hasTrack
          ? () async {
              final player = ref.read(playerProvider.notifier);
              playing ? await player.pause() : await player.resume();
            }
          : null,
    );
  }
}

class _StopButton extends ConsumerWidget {
  const _StopButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerPlayingProvider).value ?? false;
    final hasTrack = ref.watch(playerHasTrackProvider).value ?? false;
    return IconButton(
      icon: const Icon(Icons.stop),
      onPressed: hasTrack && playing
          ? () async => await ref.read(playerProvider.notifier).stop()
          : null,
    );
  }
}

class _NextButton extends ConsumerWidget {
  const _NextButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNext = ref.watch(playerHasNextProvider).value ?? false;
    return IconButton(
      icon: const Icon(Icons.skip_next),
      onPressed: hasNext
          ? () async => await ref.read(playerProvider.notifier).next()
          : null,
    );
  }
}

class _ProgressSlider extends ConsumerWidget {
  const _ProgressSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).value ?? Duration.zero;
    final dragValue = ref.watch(progressDragValueProvider);

    final durationSeconds = duration.inSeconds;
    final positionSeconds = position.inSeconds;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
      ),
      child: Slider(
        value: durationSeconds > 0
            ? (dragValue ?? positionSeconds.toDouble())
            : 0,
        max: durationSeconds.toDouble(),
        onChanged: durationSeconds > 0
            ? (value) => ref
                  .read(progressDragValueProvider.notifier)
                  .setDragValue(value)
            : null,
        onChangeEnd: (_) async {
          if (dragValue != null) {
            final playerNotifier = ref.read(playerProvider.notifier);
            await playerNotifier.seek(Duration(seconds: dragValue.toInt()));
          }
          ref.read(progressDragValueProvider.notifier).resetDragValue();
        },
      ),
    );
  }
}
