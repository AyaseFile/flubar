import 'dart:async';

import 'package:super_clipboard/super_clipboard.dart';

extension ReadValue on DataReader {
  Future<T?> readValue<T extends Object>(ValueFormat<T> format) {
    final c = Completer<T?>();
    final progress = getValue<T>(
      format,
      (value) {
        c.complete(value);
      },
      onError: (e) {
        c.completeError(e);
      },
    );
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }
}
