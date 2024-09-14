import 'package:cross_file/cross_file.dart';
import 'package:flubar/ui/dialogs/cover_dialog/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class CoverDragState extends _$CoverDragState {
  @override
  bool build() => false;

  Future<void> addFile(XFile file) async {
    final uint8List = await file.readAsBytes();
    if (ref.exists(groupedTrackCoverProvider)) {
      ref.read(groupedTrackCoverProvider.notifier).updateCoverState(uint8List);
    } else {
      ref.read(batchedTrackCoverProvider.notifier).updateCoverState(uint8List);
    }
  }

  void setDragging(bool dragging) {
    state = dragging;
  }
}
