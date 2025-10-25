import 'dart:typed_data';

import 'package:flubar/rust/api/models.dart';

extension MetadataExtension on Metadata {
  Metadata nullableCopyWith({
    // 允许传入 null 以清除值
    String? Function()? title,
    String? Function()? artist,
    String? Function()? album,
    String? Function()? albumArtist,
    int? Function()? trackNumber,
    int? Function()? trackTotal,
    int? Function()? discNumber,
    int? Function()? discTotal,
    String? Function()? date,
    String? Function()? genre,
    Uint8List? Function()? frontCover,
  }) {
    return Metadata(
      title: title != null ? title() : this.title,
      artist: artist != null ? artist() : this.artist,
      album: album != null ? album() : this.album,
      albumArtist: albumArtist != null ? albumArtist() : this.albumArtist,
      trackNumber: trackNumber != null ? trackNumber() : this.trackNumber,
      trackTotal: trackTotal != null ? trackTotal() : this.trackTotal,
      discNumber: discNumber != null ? discNumber() : this.discNumber,
      discTotal: discTotal != null ? discTotal() : this.discTotal,
      date: date != null ? date() : this.date,
      genre: genre != null ? genre() : this.genre,
      frontCover: frontCover != null ? frontCover() : this.frontCover,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (title != null) json['title'] = title;
    if (artist != null) json['artist'] = artist;
    if (album != null) json['album'] = album;
    if (albumArtist != null) json['albumartist'] = albumArtist;
    if (trackNumber != null) json['tracknumber'] = trackNumber;
    if (trackTotal != null) json['tracktotal'] = trackTotal;
    if (discNumber != null) json['discnumber'] = discNumber;
    if (discTotal != null) json['disctotal'] = discTotal;
    if (date != null) json['date'] = date;
    if (genre != null) json['genre'] = genre;
    return json;
  }
}
