import 'package:flutter/material.dart';

class RatioDialog extends StatelessWidget {
  final double widthRatio;
  final double heightRatio;
  final Widget child;

  const RatioDialog({
    super.key,
    this.widthRatio = 0.8,
    this.heightRatio = 0.8,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final maxWidth = screenWidth * widthRatio;
          final maxHeight = screenHeight * heightRatio;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class RatioAlertDialog extends StatelessWidget {
  final double widthRatio;
  final double heightRatio;
  final Widget title;
  final Widget content;
  final List<Widget> actions;

  const RatioAlertDialog({
    super.key,
    this.widthRatio = 0.8,
    this.heightRatio = 0.8,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxWidth = screenWidth * widthRatio;
    final maxHeight = screenHeight * heightRatio;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                child: DefaultTextStyle(
                  style: textTheme.headlineSmall!
                      .copyWith(color: colorScheme.onSurface),
                  child: title,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                  child: DefaultTextStyle(
                    style: textTheme.bodyMedium!
                        .copyWith(color: colorScheme.onSurfaceVariant),
                    child: content,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
