import 'package:flubar/ui/widgets/media_drag_widget/providers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class GetDialog extends _$GetDialog {
  @override
  void build() {}

  Future<T?> show<T>(Widget widget, {bool barrierDismissible = true}) async {
    assert(Get.isDialogOpen == false); // 只能在没有对话框打开时调用

    final dragNotifier = ref.read(enableMediaDragProvider.notifier);
    dragNotifier.disable();

    try {
      final result =
          await Get.dialog<T>(widget, barrierDismissible: barrierDismissible);
      return result;
    } finally {
      dragNotifier.enable();
    }
  }

  Future<void> to(Widget widget) async {
    final dragNotifier = ref.read(enableMediaDragProvider.notifier);
    dragNotifier.disable();
    await Get.to(() => widget);
    dragNotifier.enable();
  }
}
