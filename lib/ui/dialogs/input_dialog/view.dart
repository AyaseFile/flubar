import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InputDialog extends HookWidget {
  const InputDialog({
    super.key,
    required this.dialogTitle,
    this.initialValue = '',
    required this.onConfirm,
  });

  final String dialogTitle;
  final String initialValue;
  final void Function(String) onConfirm;

  @override
  Widget build(BuildContext context) {
    final ctrl = useTextEditingController(text: initialValue);
    return AlertDialog(
      title: Text(dialogTitle),
      content: TextField(controller: ctrl),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            onConfirm(ctrl.text);
            Navigator.of(context).pop();
          },
          autofocus: true,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
