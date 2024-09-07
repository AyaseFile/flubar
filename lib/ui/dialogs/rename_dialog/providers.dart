import 'package:flubar/utils/template/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class RenameProgress extends _$RenameProgress {
  @override
  double build() => 0.0;

  void setProgress(double progress) => state = progress;
}

@riverpod
class Rename extends _$Rename {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> renameFiles() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tplUtilProvider.notifier).performTasks();
    });
  }

  void cancelRename() => ref.read(tplUtilProvider.notifier).cancelTasks();
}

@riverpod
class RenameFailedCount extends _$RenameFailedCount {
  @override
  int build() => 0;

  void increment() => state++;

  void setCancelled() => state = -1;
}
