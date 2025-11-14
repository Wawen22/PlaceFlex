import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../models/moment.dart';
import 'prepared_moment_media.dart';

class MomentMediaProcessor {
  MomentMediaProcessor({VideoCompressionBridge? videoBridge})
    : _videoBridge = videoBridge ?? DefaultVideoCompressionBridge();

  final VideoCompressionBridge _videoBridge;

  Future<PreparedMomentMedia> process({
    required MomentMediaType mediaType,
    required XFile file,
    Uint8List? cachedBytes,
    Duration? recordedDuration,
  }) async {
    switch (mediaType) {
      case MomentMediaType.photo:
        return _processPhoto(file, cachedBytes);
      case MomentMediaType.video:
        return _processVideo(file);
      case MomentMediaType.audio:
        return _processAudio(file, recordedDuration);
      case MomentMediaType.text:
        throw UnsupportedError('Text moments do not require media processing');
    }
  }

  Future<PreparedMomentMedia> _processPhoto(
    XFile file,
    Uint8List? cachedBytes,
  ) async {
    final sourceBytes = cachedBytes ?? await file.readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      sourceBytes,
      quality: 85,
      minHeight: 2048,
      minWidth: 2048,
      format: CompressFormat.jpeg,
    );

    final bytes = compressedBytes ?? sourceBytes;
    return PreparedMomentMedia(
      type: MomentMediaType.photo,
      bytes: bytes,
      extension: 'jpg',
      contentType: 'image/jpeg',
      sizeBytes: bytes.length,
      previewBytes: bytes,
    );
  }

  Future<PreparedMomentMedia> _processVideo(XFile file) async {
    if (kIsWeb) {
      throw UnsupportedError('Video compression non supportata sul web');
    }

    final info = await _videoBridge.compressVideo(file.path);
    if (info == null || info.path == null) {
      throw StateError('Impossibile comprimere il video selezionato');
    }

    final outputFile = File(info.path!);
    if (!await outputFile.exists()) {
      throw StateError('File compresso non trovato');
    }

    final bytes = await outputFile.readAsBytes();
    final thumbBytes = await _videoBridge.getThumbnail(info.path!);
    final durationMs = info.duration?.round();

    return PreparedMomentMedia(
      type: MomentMediaType.video,
      bytes: bytes,
      extension: 'mp4',
      contentType: 'video/mp4',
      sizeBytes: bytes.length,
      previewBytes: thumbBytes,
      duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
    );
  }

  Future<PreparedMomentMedia> _processAudio(
    XFile file,
    Duration? recordedDuration,
  ) async {
    final bytes = await file.readAsBytes();
    return PreparedMomentMedia(
      type: MomentMediaType.audio,
      bytes: bytes,
      extension: 'm4a',
      contentType: 'audio/mp4',
      sizeBytes: bytes.length,
      duration: recordedDuration,
    );
  }
}

abstract class VideoCompressionBridge {
  Future<MediaInfo?> compressVideo(String path);

  Future<Uint8List?> getThumbnail(String path);
}

class DefaultVideoCompressionBridge implements VideoCompressionBridge {
  @override
  Future<MediaInfo?> compressVideo(String path) {
    return VideoCompress.compressVideo(
      path,
      quality: VideoQuality.MediumQuality,
      includeAudio: true,
      deleteOrigin: false,
    );
  }

  @override
  Future<Uint8List?> getThumbnail(String path) async {
    final file = await VideoCompress.getFileThumbnail(
      path,
      quality: 80,
      position: -1,
    );
    if (file == null) {
      return null;
    }
    return file.readAsBytes();
  }
}
