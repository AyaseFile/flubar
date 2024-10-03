import 'package:flutter/material.dart';

class FixedSizeDialog extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const FixedSizeDialog({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
