import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/models/extensions/properties_extension.dart';
import 'package:flubar/models/state/common_properties.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'constants.dart';

part 'providers.g.dart';

@riverpod
class CommonProperties extends _$CommonProperties {
  @override
  IList<CommonPropertiesModel> build() {
    final selectedTracks = ref.watch(selectedTracksProvider);
    final properties = selectedTracks.map((track) => track.properties);
    var totalDuration = 0.0;
    for (final property in properties) {
      totalDuration += property.duration ?? 0;
    }
    final duration = formatDuration(totalDuration);
    final codec =
        _formatStringProperty(properties.map((property) => property.codec));
    final sampleFormat = _formatStringProperty(
        properties.map((property) => property.sampleFormat));
    final sampleRate = _formatIntProperty(
        properties.map((property) => property.sampleRate),
        suffix: 'Hz');
    final bitsPerRawSample = _formatIntProperty(
        properties.map((property) => property.bitsPerRawSample),
        suffix: 'bit');
    final bitsPerCodedSample = _formatIntProperty(
        properties.map((property) => property.bitsPerCodedSample),
        suffix: 'bit');
    final bitRate = _formatIntProperty(properties.map((property) {
      final bitRate = property.bitRate;
      if (bitRate != null) {
        return (bitRate / 1000).round();
      }
      return null;
    }), suffix: 'kbps');
    final channels =
        _formatIntProperty(properties.map((property) => property.channels));

    return IList([
      CommonPropertiesModel(id: kDurationRowId, key: '时长', value: duration),
      CommonPropertiesModel(id: kCodecRowId, key: '编码', value: codec),
      CommonPropertiesModel(
          id: kSampleFormatRowId, key: '采样格式', value: sampleFormat),
      CommonPropertiesModel(
          id: kSampleRateRowId, key: '采样率', value: sampleRate),
      CommonPropertiesModel(
          id: kBitsPerRawSampleRowId, key: '原始采样位数', value: bitsPerRawSample),
      CommonPropertiesModel(
          id: kBitsPerCodedSampleRowId, key: '采样位数', value: bitsPerCodedSample),
      CommonPropertiesModel(id: kBitRateRowId, key: '比特率', value: bitRate),
      CommonPropertiesModel(id: kChannelsRowId, key: '声道', value: channels),
    ]);
  }

  String _formatIntProperty(Iterable<int?> values, {String suffix = ''}) {
    if (values.isEmpty) return '未知';

    final Map<int, int> countMap = {};
    int totalCount = 0;

    for (final value in values) {
      if (value != null) {
        countMap[value] = (countMap[value] ?? 0) + 1;
      } else {
        countMap[-1] = (countMap[-1] ?? 0) + 1;
      }
      totalCount++;
    }

    if (countMap.isEmpty) return '未知';
    if (countMap.length == 1) {
      return countMap.keys.first == -1 ? '未知' : '${countMap.keys.first}$suffix';
    }

    final formattedValues = countMap.entries.map((entry) {
      final unknown = entry.key == -1;
      final key = unknown ? '未知' : entry.key.toString();
      final percentage = (entry.value / totalCount * 100).toStringAsFixed(2);
      return unknown ? '$key ($percentage%)' : '$key$suffix ($percentage%)';
    }).toList();

    return formattedValues.join(', ');
  }

  String _formatStringProperty(Iterable<String?> values, {String suffix = ''}) {
    if (values.isEmpty) return '未知';

    final Map<String, int> countMap = {};
    int totalCount = 0;

    for (final value in values) {
      if (value != null && value.isNotEmpty) {
        countMap[value] = (countMap[value] ?? 0) + 1;
      } else {
        countMap['未知'] = (countMap['未知'] ?? 0) + 1;
      }
      totalCount++;
    }

    if (countMap.isEmpty) return '未知';
    if (countMap.length == 1) {
      return countMap.keys.first == '未知'
          ? '未知'
          : '${countMap.keys.first}$suffix';
    }

    final formattedValues = countMap.entries.map((entry) {
      final unknown = entry.key == '未知';
      final key = unknown ? '未知' : entry.key;
      final percentage = (entry.value / totalCount * 100).toStringAsFixed(2);
      return unknown ? '$key ($percentage%)' : '$key$suffix ($percentage%)';
    }).toList();

    return formattedValues.join(', ');
  }

  static String formatDuration(double? durationSeconds) {
    if (durationSeconds == null || durationSeconds.isNaN) return '00:00';
    final duration = Duration(seconds: durationSeconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

@riverpod
CommonPropertiesModel commonPropertiesItem(Ref ref) =>
    throw UnimplementedError();
