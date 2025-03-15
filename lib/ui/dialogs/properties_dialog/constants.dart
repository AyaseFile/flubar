import 'package:flubar/ui/view/tracklist_view/constants.dart';
import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';

const kDurationRowId = 0;
const kCodecRowId = 1;
const kSampleFormatRowId = 2;
const kSampleRateRowId = 3;
const kBitsPerRawSampleRowId = 4;
const kBitsPerCodedSampleRowId = 5;
const kBitRateRowId = 6;
const kChannelsRowId = 7;

const kKeyColumnIndex = 0;
const kValueColumnIndex = 1;

const kKeyColumnWidth = 100.0;
const kValueColumnWidth = 380.0;

const kPropertiesColumns = [
  TableColumn(width: kKeyColumnWidth),
  TableColumn(width: kValueColumnWidth)
];

const kDialogWidth = 400.0;
const kDialogHeight = 300.0;

const kTooltipTheme = TooltipThemeData(
  verticalOffset: -kRowHeight / 3,
  margin: EdgeInsets.all(2.0),
  padding: EdgeInsets.all(2.0),
);
const kWaitDuration = Duration(milliseconds: 300);
