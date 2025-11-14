import 'dart:typed_data';

import '../models/moment.dart';

class PreparedMomentMedia {
  PreparedMomentMedia({
    required this.type,
    required this.bytes,
    required this.extension,
    required this.contentType,
    required this.sizeBytes,
    this.previewBytes,
    this.duration,
  });

  final MomentMediaType type;
  final Uint8List bytes;
  final String extension;
  final String contentType;
  final int sizeBytes;
  final Uint8List? previewBytes;
  final Duration? duration;

  int? get durationMs => duration?.inMilliseconds;
}
