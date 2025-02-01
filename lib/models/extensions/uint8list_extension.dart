import 'dart:typed_data';

import 'package:collection/collection.dart';

extension Uint8ListExtension on Uint8List {
  bool isContentEqual(ListEquality listEquality, Uint8List? other) {
    if (other == null) return false;
    return listEquality.equals(this, other);
  }
}
