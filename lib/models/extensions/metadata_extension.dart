import 'dart:typed_data';

import 'package:flubar/rust/api/models.dart';

extension MetadataExtension on Metadata {
  Metadata copyWith({
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
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'albumartist': albumArtist,
      'tracknumber': trackNumber,
      'tracktotal': trackTotal,
      'discnumber': discNumber,
      'disctotal': discTotal,
      'date': date,
      'genre': genre,
    };
  }
}
