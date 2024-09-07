import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SliderDialog extends HookConsumerWidget {
  const SliderDialog({
    super.key,
    required this.title,
    required this.min,
    required this.max,
    required this.divisions,
    required this.initialValue,
    required this.onChanged,
    this.labelSuffix = '',
  });

  final String title;
  final double min;
  final double max;
  final int divisions;
  final int initialValue;
  final void Function(int) onChanged;
  final String labelSuffix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valueNotifier = useValueNotifier(initialValue.toDouble());
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('${min.toInt()}$labelSuffix'),
              Expanded(
                child: HookBuilder(
                  builder: (context) {
                    final value = useValueListenable(valueNotifier);
                    return Slider(
                      min: min,
                      max: max,
                      divisions: divisions,
                      value: value,
                      onChanged: (newValue) {
                        valueNotifier.value = newValue;
                      },
                    );
                  },
                ),
              ),
              Text('${max.toInt()}$labelSuffix'),
            ],
          ),
          HookBuilder(
            builder: (context) {
              final value = useValueListenable(valueNotifier);
              return Text(
                '${value.toInt()}$labelSuffix',
                style: Theme.of(context).textTheme.titleMedium,
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            onChanged(valueNotifier.value.toInt());
            Navigator.of(context).pop();
          },
          autofocus: true,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
