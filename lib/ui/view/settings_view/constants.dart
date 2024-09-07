import 'package:flubar/models/state/track.dart';
import 'package:metadata_god/metadata_god.dart';

const kExampleTrack = Track(
  id: 0721,
  path: '/path/to/track.mp3',
  metadata: Metadata(
    tagType: TagType.id3,
    title: '恋ひ恋ふ縁',
    artist: 'KOTOKO',
    album: '千恋*万花 オリジナルサウンドトラック',
    albumArtist: 'Famishin',
    trackNumber: 1,
    trackTotal: 14,
    discNumber: 3,
    discTotal: 3,
    year: 2016,
    genre: 'OST',
  ),
);
