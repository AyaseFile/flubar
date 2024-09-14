import 'package:flubar/rust/api/models.dart';
import 'package:path/path.dart' as p;

class _CompileResult {
  final List<String> _parts;
  final List<String> _keys;

  _CompileResult(this._parts, this._keys);
}

class TemplateProcessor {
  final List<String> _parts;
  final List<String> _keys;

  TemplateProcessor(String template)
      : _parts = _compile(template)._parts,
        _keys = _compile(template)._keys;

  static _CompileResult _compile(String template) {
    final parts = <String>[];
    final keys = <String>[];
    final matches = RegExp(r'%(\w+)%').allMatches(template);

    var lastIndex = 0;
    for (final match in matches) {
      parts.add(template.substring(lastIndex, match.start));
      parts.add(match.group(0)!);
      keys.add(match.group(1)!);
      lastIndex = match.end;
    }
    parts.add(template.substring(lastIndex));

    return _CompileResult(parts, keys);
  }

  String process(
      {required String path, required Metadata metadata, String? extension}) {
    final ext = p.extension(path);
    final buffer = StringBuffer();

    String? getValue(String key) {
      switch (key) {
        case 'filename':
          return p.basenameWithoutExtension(path);
        case 'title':
          return metadata.title;
        case 'artist':
          return metadata.artist;
        case 'album':
          return metadata.album;
        case 'albumartist':
          return metadata.albumArtist;
        case 'tracknumber':
          return metadata.trackNumber?.toString().padLeft(2, '0');
        case 'tracktotal':
          return metadata.trackTotal?.toString();
        case 'discnumber':
          return metadata.discNumber?.toString();
        case 'disctotal':
          return metadata.discTotal?.toString();
        case 'date':
          return metadata.date?.toString();
        case 'genre':
          return metadata.genre;
        default:
          return null;
      }
    }

    for (var i = 0; i < _parts.length; i++) {
      final part = _parts[i];
      if (part.startsWith('%') && part.endsWith('%')) {
        final key = _keys[i ~/ 2];
        final value = getValue(key) ?? '';
        buffer.write(value);
      } else {
        buffer.write(part);
      }
    }
    return buffer.toString() + (extension ?? ext);
  }
}
