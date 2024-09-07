import 'package:flubar/ui/snackbar/view.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart' hide TalkerWrapper;

class TalkerWrapper extends StatelessWidget {
  final Talker talker;
  final Widget child;

  const TalkerWrapper({super.key, required this.talker, required this.child});

  @override
  Widget build(BuildContext context) {
    return TalkerListener(
      talker: talker,
      listener: (data) {
        if (data is TalkerException) {
          showExceptionSnackbar(
              title: '异常', message: _mapErrorMessage(data.displayException));
        } else if (data is TalkerError) {
          showExceptionSnackbar(
              title: '错误', message: _mapErrorMessage(data.displayError));
        }
      },
      child: child,
    );
  }

  String _mapErrorMessage(String errorMessage) {
    final errorParts = errorMessage.split('\n');
    if (errorParts.length < 2) {
      return errorMessage;
    }
    return errorParts.getRange(1, 2).join('\n');
  }
}
