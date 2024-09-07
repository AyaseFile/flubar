import 'dart:async';

import 'package:flubar/app/talker.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
class Player extends _$Player {
  static final AudioPlayer _player = AudioPlayer();

  @override
  void build() {
    // 添加空的播放列表
    _player.setAudioSource(ConcatenatingAudioSource(children: []));
    ref.onDispose(() => _player.dispose());
  }

  static Future<void> handleError() async {
    try {
      await _player.stop();
      await _player.setAudioSource(ConcatenatingAudioSource(children: []));
    } on PlayerException catch (e) {
      globalTalker.handle(e, null, '无法停止播放器');
    }
  }

  Future<void> play() async {
    final selectedTracks = ref.read(selectedTracksProvider);
    final sources = selectedTracks
        .map((track) => AudioSource.file(track.path, tag: track.metadata))
        .toList();
    try {
      await _player.setAudioSource(ConcatenatingAudioSource(children: sources),
          preload: false);
      await _player.play();
    } on PlayerException catch (e) {
      globalTalker.handle(e, null, '无法播放音频');
    }
  }

  Future<void> pause() async => await _player.pause();

  Future<void> resume() async => await _player.play();

  Future<void> stop() async {
    await _player.stop();
    await _player.setAudioSource(ConcatenatingAudioSource(children: []));
  }

  Future<void> previous() async => await _player.seekToPrevious();

  Future<void> next() async => await _player.seekToNext();

  Future<void> seek(Duration position) async => await _player.seek(position);

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  Stream<bool> get hasTrack => sequenceStateStream.map((state) =>
      state?.sequence.isNotEmpty == true &&
      state!.currentIndex < state.sequence.length);

  Stream<bool> get hasNext => sequenceStateStream.map((state) =>
      state?.sequence.isNotEmpty == true &&
      state!.currentIndex < state.sequence.length - 1);

  Stream<bool> get hasPrevious =>
      sequenceStateStream.map((state) => (state?.currentIndex ?? 0) > 0);
}

@Riverpod(keepAlive: true)
Stream<PlayerState> playerState(PlayerStateRef ref) =>
    ref.read(playerProvider.notifier).playerStateStream;

@Riverpod(keepAlive: true)
AsyncValue<bool> playerPlaying(PlayerPlayingRef ref) {
  final playerState = ref.watch(playerStateProvider);
  final hasTrack = ref.watch(playerHasTrackProvider);
  globalTalker.debug('当前播放器状态: $playerState');
  return playerState
      .whenData((state) => hasTrack.valueOrNull == true && state.playing);
}

@Riverpod(keepAlive: true)
Stream<Duration> playerPosition(PlayerPositionRef ref) {
  final playing = ref.watch(playerPlayingProvider);
  final positionStream = ref.read(playerProvider.notifier).positionStream;

  return playing.when(
    data: (playing) => playing ? positionStream : Stream.value(Duration.zero),
    loading: () => Stream.value(Duration.zero),
    error: (e, st) => Stream.value(Duration.zero),
  );
}

@Riverpod(keepAlive: true)
Stream<Duration> playerDuration(PlayerDurationRef ref) => ref
    .read(playerProvider.notifier)
    .durationStream
    .map((duration) => duration ?? Duration.zero);

@Riverpod(keepAlive: true)
Stream<bool> playerHasTrack(PlayerHasTrackRef ref) =>
    ref.read(playerProvider.notifier).hasTrack;

@Riverpod(keepAlive: true)
Stream<bool> playerHasNext(PlayerHasNextRef ref) =>
    ref.read(playerProvider.notifier).hasNext;

@Riverpod(keepAlive: true)
Stream<bool> playerHasPrevious(PlayerHasPreviousRef ref) =>
    ref.read(playerProvider.notifier).hasPrevious;

@Riverpod(keepAlive: true)
Stream<Metadata?> playerTrackMetadata(PlayerTrackMetadataRef ref) {
  final sequenceStateStream =
      ref.watch(playerProvider.notifier).sequenceStateStream;
  return sequenceStateStream
      .map((sequenceState) => sequenceState?.currentSource?.tag as Metadata?);
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
