import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../models/moment.dart';

class CreateMomentInput {
  CreateMomentInput({
    required this.profileId,
    required this.title,
    this.description,
    required this.mediaType,
    this.mediaFile,
    this.mediaBytes,
    required this.visibility,
    required this.latitude,
    required this.longitude,
    this.tags = const [],
    this.radiusMeters = 100,
    this.status = MomentStatus.published,
  });

  final String profileId;
  final String title;
  final String? description;
  final MomentMediaType mediaType;
  final XFile? mediaFile;
  final Uint8List? mediaBytes;
  final MomentVisibility visibility;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final int radiusMeters;
  final MomentStatus status;
}

class MomentsRepository {
  MomentsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Moment> createMoment(CreateMomentInput input) async {
    final bucketRef = _client.storage.from(AppConstants.momentsBucket);

    await _ensureBucketExists();

    String? mediaUrl;
    String? thumbnailUrl;

    if (input.mediaType != MomentMediaType.text) {
      final uploadResult = await _uploadMedia(
        bucketRef,
        input.mediaFile,
        input.mediaBytes,
        input,
      );
      mediaUrl = uploadResult?.mediaUrl;
      thumbnailUrl = uploadResult?.thumbnailUrl;
    }

    final payload = <String, dynamic>{
      'profile_id': input.profileId,
      'title': input.title,
      'description': input.description,
      'media_type': input.mediaType.name,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'visibility': input.visibility.name,
      'status': input.status.name,
      'tags': input.tags,
      'radius_m': input.radiusMeters,
      'location': {
        'type': 'Point',
        'coordinates': [input.longitude, input.latitude],
      },
    };

    final inserted = await _client
        .from('moments')
        .insert(payload)
        .select()
        .maybeSingle();

    if (inserted == null) {
      throw StateError('Creazione momento fallita.');
    }

    return Moment.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<_UploadResult?> _uploadMedia(
    StorageFileApi bucketRef,
    XFile? file,
    Uint8List? bytes,
    CreateMomentInput input,
  ) async {
    if (file == null && bytes == null) {
      throw ArgumentError(
        'File media richiesto per il tipo ${input.mediaType.name}',
      );
    }

    final byteData = bytes ?? await file!.readAsBytes();

    final extension = _resolveExtension(input.mediaType, file);
    final contentType = _resolveContentType(input.mediaType, file);
    final fileName = _buildFilename(input.profileId, extension);

    final path = '${input.profileId}/$fileName';

    await bucketRef.uploadBinary(
      path,
      byteData,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

    final publicUrl = bucketRef.getPublicUrl(path);

    return _UploadResult(mediaUrl: publicUrl, thumbnailUrl: null);
  }

  Future<void> _ensureBucketExists() async {
    try {
      await _client.storage.createBucket(
        AppConstants.momentsBucket,
        const BucketOptions(public: true),
      );
    } on StorageException catch (error) {
      if ('${error.statusCode}' == '409') {
        return;
      }
      rethrow;
    }
  }

  String _buildFilename(String profileId, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${profileId}_$timestamp.$extension';
  }

  String _resolveExtension(MomentMediaType type, XFile? file) {
    final detected = _detectExtension(file);
    if (detected != null && detected.isNotEmpty) {
      return detected;
    }

    switch (type) {
      case MomentMediaType.photo:
        return 'jpg';
      case MomentMediaType.video:
        return 'mp4';
      case MomentMediaType.audio:
        return 'm4a';
      case MomentMediaType.text:
        return 'txt';
    }
  }

  String _resolveContentType(MomentMediaType type, XFile? file) {
    final mimeType = file?.mimeType;
    if (mimeType != null && mimeType.isNotEmpty) {
      return mimeType;
    }

    switch (type) {
      case MomentMediaType.photo:
        return 'image/jpeg';
      case MomentMediaType.video:
        return 'video/mp4';
      case MomentMediaType.audio:
        return 'audio/mp4';
      case MomentMediaType.text:
        return 'text/plain';
    }
  }

  String? _detectExtension(XFile? file) {
    if (file == null) return null;

    final name = file.name;
    final fromName = _extensionFromValue(name);
    if (fromName != null) {
      return fromName;
    }

    final path = file.path;
    final fromPath = _extensionFromValue(path);
    if (fromPath != null) {
      return fromPath;
    }

    final mimeType = file.mimeType;
    if (mimeType != null && mimeType.contains('/')) {
      return mimeType.split('/').last;
    }

    return null;
  }

  String? _extensionFromValue(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final dotIndex = value.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == value.length - 1) {
      return null;
    }

    return value.substring(dotIndex + 1);
  }

  /// Recupera momenti entro un raggio specificato da coordinate centrali
  /// Usa RPC function con PostGIS ST_DWithin per query spaziale
  Future<List<Moment>> getNearbyMoments({
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
    int limit = 200,
  }) async {
    try {
      // Usa la RPC function invece del filter (PostgREST non supporta filtri PostGIS)
      final response = await _client.rpc(
        'get_nearby_moments',
        params: {
          'center_lat': centerLat,
          'center_lon': centerLon,
          'radius_meters': radiusMeters,
          'result_limit': limit,
        },
      );

      return (response as List)
          .map((json) => Moment.fromMap(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching nearby moments: $e');
      }
      rethrow;
    }
  }

  /// Recupera momenti all'interno di un bounding box
  /// Usa RPC function per query viewport mappa
  Future<List<Moment>> getMomentsInBounds({
    required double swLat,
    required double swLon,
    required double neLat,
    required double neLon,
    int limit = 200,
  }) async {
    try {
      // Usa la RPC function invece del filter (PostgREST non supporta filtri PostGIS)
      final response = await _client.rpc(
        'get_moments_in_bounds',
        params: {
          'sw_lat': swLat,
          'sw_lon': swLon,
          'ne_lat': neLat,
          'ne_lon': neLon,
          'result_limit': limit,
        },
      );

      return (response as List)
          .map((json) => Moment.fromMap(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching moments in bounds: $e');
      }
      rethrow;
    }
  }
}

class _UploadResult {
  _UploadResult({required this.mediaUrl, this.thumbnailUrl});

  final String mediaUrl;
  final String? thumbnailUrl;
}
