import 'package:freezed_annotation/freezed_annotation.dart';

part 'advanced_column_state.freezed.dart';

part 'advanced_column_state.g.dart';

@freezed
abstract class AdvancedColumnState with _$AdvancedColumnState {
  const factory AdvancedColumnState({required int id, required double width}) =
      _AdvancedColumnState;

  factory AdvancedColumnState.fromJson(Map<String, dynamic> json) =>
      _$AdvancedColumnStateFromJson(json);
}
