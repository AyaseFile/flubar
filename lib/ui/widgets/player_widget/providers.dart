// ignore_for_file: avoid_public_notifier_properties
import 'dart:async';

import 'package:flubar/app/talker.dart';
import 'package:flubar/models/extensions/properties_extension.dart';
import 'package:flubar/rust/api/models.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
class Player extends _$Player {
  static final AudioPlayer _player = AudioPlayer();

  @override
  void build() {
    // 添加空的播放列表
    _player.setAudioSources([]);
    ref.onDispose(() => _player.dispose());
  }

  static Future<void> handleError() async {
    try {
      await _player.stop();
      await _player.setAudioSources([]);
    } on PlayerException catch (e) {
      globalTalker.handle(e, null, '无法停止播放器');
    }
  }

  Future<void> play() async {
    await stop();
    final selectedTracks = ref.read(selectedTracksProvider);
    final sources = selectedTracks.map((track) {
      if (track.properties.isCue() && track.properties.cueStartSec != null) {
        final start = Duration(
          milliseconds: (track.properties.cueStartSec! * 1000).round(),
        );
        final end = track.properties.cueDurationSec != null
            ? start +
                  Duration(
                    milliseconds: (track.properties.cueDurationSec! * 1000)
                        .round(),
                  )
            : null;

        return ClippingAudioSource(
          child: AudioSource.file(track.path, tag: track.metadata),
          start: start,
          end: end,
        );
      } else {
        return AudioSource.file(track.path, tag: track.metadata);
      }
    }).toList();

    try {
      await _player.setAudioSources(sources, preload: false);
      await _player.play();
    } on PlayerException catch (e) {
      globalTalker.handle(e, null, '无法播放音频');
    }
  }

  Future<void> pause() async => await _player.pause();

  Future<void> resume() async => await _player.play();

  Future<void> stop() async {
    await _player.stop();
    await _player.setAudioSources([]);
  }

  Future<void> previous() async => await _player.seekToPrevious();

  Future<void> next() async => await _player.seekToNext();

  Duration _clampDuration(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  Future<void> seek(Duration position) async {
    final clip = _getCurrentClip();
    if (clip != null) {
      final start = clip.start ?? Duration.zero;
      final end = clip.end ?? _player.duration ?? Duration.zero;
      final clampedPosition = _clampDuration(
        position,
        Duration.zero,
        end - start,
      );
      await _player.seek(clampedPosition + start);
    } else {
      await _player.seek(position);
    }
  }

  ClippingAudioSource? _getCurrentClip() {
    final currentSource = _player.sequence.elementAtOrNull(
      _player.currentIndex ?? -1,
    );
    return currentSource is ClippingAudioSource ? currentSource : null;
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration> get positionStream => _player.positionStream.map((position) {
    final clip = _getCurrentClip();
    if (clip != null) {
      final start = clip.start ?? Duration.zero;
      final end = clip.end ?? position;
      return _clampDuration(position - start, Duration.zero, end - start);
    }
    return position;
  });

  Stream<Duration> get durationStream =>
      _player.durationStream.map((fullDuration) {
        fullDuration ??= Duration.zero;
        final clip = _getCurrentClip();
        if (clip != null) {
          final start = clip.start ?? Duration.zero;
          final end = clip.end ?? fullDuration;
          return _clampDuration(end - start, Duration.zero, fullDuration);
        }
        return fullDuration;
      });

  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  Stream<bool> get hasTrack => sequenceStateStream.map(
    (state) =>
        state?.sequence.isNotEmpty == true &&
        state!.currentIndex! < state.sequence.length,
  );

  Stream<bool> get hasNext => sequenceStateStream.map(
    (state) =>
        state?.sequence.isNotEmpty == true &&
        state!.currentIndex! < state.sequence.length - 1,
  );

  Stream<bool> get hasPrevious =>
      sequenceStateStream.map((state) => (state?.currentIndex ?? 0) > 0);
}

@Riverpod(keepAlive: true)
Stream<PlayerState> playerState(Ref ref) =>
    ref.read(playerProvider.notifier).playerStateStream;

@Riverpod(keepAlive: true)
AsyncValue<bool> playerPlaying(Ref ref) {
  final playerState = ref.watch(playerStateProvider);
  final hasTrack = ref.watch(playerHasTrackProvider);
  // globalTalker.debug('当前播放器状态: $playerState');
  return playerState.whenData(
    (state) => hasTrack.value == true && state.playing,
  );
}

@Riverpod(keepAlive: true)
Stream<Duration> playerPosition(Ref ref) {
  final playing = ref.watch(playerPlayingProvider);
  final positionStream = ref.watch(playerProvider.notifier).positionStream;

  return playing.when(
    data: (playing) => playing ? positionStream : Stream.value(Duration.zero),
    loading: () => Stream.value(Duration.zero),
    error: (e, st) => Stream.value(Duration.zero),
  );
}

@Riverpod(keepAlive: true)
Stream<Duration> playerDuration(Ref ref) =>
    ref.read(playerProvider.notifier).durationStream;

@Riverpod(keepAlive: true)
Stream<bool> playerHasTrack(Ref ref) =>
    ref.read(playerProvider.notifier).hasTrack;

@Riverpod(keepAlive: true)
Stream<bool> playerHasNext(Ref ref) =>
    ref.read(playerProvider.notifier).hasNext;

@Riverpod(keepAlive: true)
Stream<bool> playerHasPrevious(Ref ref) =>
    ref.read(playerProvider.notifier).hasPrevious;

@Riverpod(keepAlive: true)
Stream<Metadata?> playerTrackMetadata(Ref ref) {
  final sequenceStateStream = ref
      .watch(playerProvider.notifier)
      .sequenceStateStream;
  return sequenceStateStream.map((sequenceState) {
    final currentSource = sequenceState?.currentSource;
    if (currentSource == null) return null;
    if (currentSource is ClippingAudioSource) {
      return currentSource.child.tag as Metadata?;
    } else {
      return currentSource.tag as Metadata?;
    }
  });
}

@Riverpod(keepAlive: true)
class ProgressDragValue extends _$ProgressDragValue {
  @override
  double? build() => null;

  void setDragValue(double value) {
    state = value;
  }

  void resetDragValue() {
    state = null;
  }
}
