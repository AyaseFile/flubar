import 'package:material_table_view/material_table_view.dart';

const kTrackTitleRowId = 0;
const kArtistNameRowId = 1;
const kAlbumRowId = 2;
const kAlbumArtistRowId = 3;
const kTrackNumberRowId = 4;
const kTrackTotalRowId = 5;
const kDiscNumberRowId = 6;
const kDiscTotalRowId = 7;
const kDateRowId = 8;
const kGenreRowId = 9;

const kKeyColumnIndex = 0;
const kValueColumnIndex = 1;

const kKeyColumnWidth = 150.0;
const kValueColumnWidth = 380.0;

const kMetadataColumns = [
  TableColumn(width: kKeyColumnWidth),
  TableColumn(width: kValueColumnWidth)
];

const kDialogWidth = 600.0;
const kDialogHeight = 450.0;
