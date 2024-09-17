import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

import 'constants.dart';

@immutable
class AdvancedColumn extends TableColumn {
  final int id;

  @override
  final ValueKey<int> key;

  AdvancedColumn({
    required this.id,
    required super.width,
    super.minResizeWidth = kMinColumnWidth,
    super.maxResizeWidth,
    super.translation = 0,
  }) : key = ValueKey(id);

  @override
  AdvancedColumn copyWith({
    int? flex,
    int? freezePriority,
    double? maxResizeWidth,
    double? minResizeWidth,
    bool? sticky,
    double? translation,
    double? width,
  }) {
    return AdvancedColumn(
      id: id,
      maxResizeWidth: maxResizeWidth ?? this.maxResizeWidth,
      minResizeWidth: minResizeWidth ?? this.minResizeWidth,
      translation: translation ?? this.translation,
      width: width ?? this.width,
    );
  }
}
