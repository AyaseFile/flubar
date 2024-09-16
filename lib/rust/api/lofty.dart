// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.3.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'models.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// These functions are ignored because they are not marked as `pub`: `force_create_tag_for_file`, `get_or_create_tag_for_file`, `get_tagged_file`

Future<void> loftyWriteMetadata(
        {required String file,
        required Metadata metadata,
        required bool force}) =>
    RustLib.instance.api.crateApiLoftyLoftyWriteMetadata(
        file: file, metadata: metadata, force: force);

Future<void> loftyWritePicture(
        {required String file, Uint8List? picture, required bool force}) =>
    RustLib.instance.api.crateApiLoftyLoftyWritePicture(
        file: file, picture: picture, force: force);
