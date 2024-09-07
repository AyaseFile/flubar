import 'package:metadata_god/metadata_god.dart';

extension MetadataExtension on Metadata {
  Metadata copyWith({
    TagType? tagType,
    // 允许传入 null 以清除值
    String? Function()? title,
    String? Function()? artist,
    String? Function()? album,
    String? Function()? albumArtist,
    int? Function()? trackNumber,
    int? Function()? trackTotal,
    int? Function()? discNumber,
    int? Function()? discTotal,
    int? Function()? year,
    String? Function()? genre,
    Picture? Function()? picture,
  }) {
    return Metadata(
      tagType: tagType ?? this.tagType,
      title: title != null ? title() : this.title,
      artist: artist != null ? artist() : this.artist,
      album: album != null ? album() : this.album,
      albumArtist: albumArtist != null ? albumArtist() : this.albumArtist,
      trackNumber: trackNumber != null ? trackNumber() : this.trackNumber,
      trackTotal: trackTotal != null ? trackTotal() : this.trackTotal,
      discNumber: discNumber != null ? discNumber() : this.discNumber,
      discTotal: discTotal != null ? discTotal() : this.discTotal,
      year: year != null ? year() : this.year,
      genre: genre != null ? genre() : this.genre,
      picture: picture != null ? picture() : this.picture,
      durationMs: durationMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tagtype': tagType,
      'title': title,
      'artist': artist,
      'album': album,
      'albumartist': albumArtist,
      'tracknumber': trackNumber,
      'tracktotal': trackTotal,
      'discnumber': discNumber,
      'disctotal': discTotal,
      'year': year,
      'genre': genre,
      'durationms': durationMs,
    };
  }
}
