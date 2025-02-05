import 'package:flubar/models/state/advanced_column_state.dart';
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
    super.maxResizeWidth,
    super.minResizeWidth = kMinColumnWidth,
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

  factory AdvancedColumn.fromState(AdvancedColumnState state) {
    return AdvancedColumn(
      id: state.id,
      minResizeWidth: kMinColumnWidth,
      width: state.width,
    );
  }

  AdvancedColumnState toState() {
    return AdvancedColumnState(
      id: id,
      width: width,
    );
  }
}
