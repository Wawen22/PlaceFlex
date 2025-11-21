
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../models/moment.dart';
import 'moment_media_processor.dart';
import 'prepared_moment_media.dart';

class CreateMomentInput {
  CreateMomentInput({
    required this.profileId,
    required this.title,
    this.description,
    required this.mediaType,
    this.mediaFile,
    this.mediaBytes,
    this.preparedMedia,
    this.mediaSizeBytes,
    this.mediaDurationMs,
    required this.visibility,
    required this.latitude,
    required this.longitude,
    this.tags = const [],
    this.radiusMeters = 100,
    this.status = MomentStatus.published,
    this.processingStatus = MomentMediaProcessingStatus.ready,
    this.processingError,
  });

  final String profileId;
  final String title;
  final String? description;
  final MomentMediaType mediaType;
  final XFile? mediaFile;
  final Uint8List? mediaBytes;
  final PreparedMomentMedia? preparedMedia;
  final int? mediaSizeBytes;
  final int? mediaDurationMs;
  final MomentVisibility visibility;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final int radiusMeters;
  final MomentStatus status;
  final MomentMediaProcessingStatus processingStatus;
  final String? processingError;
}

class MomentsRepository {
  MomentsRepository({SupabaseClient? client, MomentMediaProcessor? mediaProcessor})
    : _client = client ?? Supabase.instance.client,
      _mediaProcessor = mediaProcessor ?? MomentMediaProcessor();

  final SupabaseClient _client;
  final MomentMediaProcessor _mediaProcessor;

  Future<Moment> createMoment(
    CreateMomentInput input, {
    ValueChanged<MediaUploadProgress>? onProgress,
  }) async {
    final bucketRef = _client.storage.from(AppConstants.momentsBucket);

    String? mediaUrl;
    String? thumbnailUrl;
    PreparedMomentMedia? preparedMedia = input.preparedMedia;

    if (input.mediaType != MomentMediaType.text) {
      preparedMedia ??= await _mediaProcessor.process(
        mediaType: input.mediaType,
        file: input.mediaFile ??
            (throw ArgumentError(
              'File richiesto per il tipo ${input.mediaType.name}',
            )),
        cachedBytes: input.mediaBytes,
        recordedDuration: input.mediaDurationMs != null
            ? Duration(milliseconds: input.mediaDurationMs!)
            : null,
      );
    }

    if (preparedMedia != null) {
      onProgress?.call(
        MediaUploadProgress(phase: MediaUploadPhase.preparing, progress: 0.15),
      );
      final uploadResult = await _uploadMedia(
        bucketRef,
        preparedMedia,
        input.profileId,
        onProgress,
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
      'media_size_bytes': input.mediaSizeBytes ?? preparedMedia?.sizeBytes,
      'media_duration_ms':
          input.mediaDurationMs ?? preparedMedia?.durationMs,
      'visibility': input.visibility.name,
      'status': input.status.name,
      'media_processing_status': input.processingStatus.name,
      'media_processing_error': input.processingError,
      'tags': input.tags,
      'radius_m': input.radiusMeters,
      'location': {
        'type': 'Point',
        'coordinates': [input.longitude, input.latitude],
      },
    };

    onProgress?.call(
      MediaUploadProgress(phase: MediaUploadPhase.saving, progress: 0.9),
    );

    final inserted = await _client
        .from('moments')
        .insert(payload)
        .select()
        .maybeSingle();

    if (inserted == null) {
      throw StateError('Creazione momento fallita.');
    }

    final moment = Moment.fromMap(Map<String, dynamic>.from(inserted));
    onProgress?.call(
      MediaUploadProgress(phase: MediaUploadPhase.completed, progress: 1),
    );
    return moment;
  }

  Future<_UploadResult?> _uploadMedia(
    StorageFileApi bucketRef,
    PreparedMomentMedia media,
    String profileId,
    ValueChanged<MediaUploadProgress>? onProgress,
  ) async {
    final fileName = _buildFilename(profileId, media.extension);
    final path = '$profileId/$fileName';

    onProgress?.call(
      MediaUploadProgress(phase: MediaUploadPhase.uploading, progress: 0.35),
    );
    await bucketRef.uploadBinary(
      path,
      media.bytes,
      fileOptions: FileOptions(contentType: media.contentType, upsert: true),
    );

    onProgress?.call(
      MediaUploadProgress(phase: MediaUploadPhase.uploading, progress: 0.7),
    );

    final publicUrl = bucketRef.getPublicUrl(path);

    String? thumbnailUrl;
    if (media.previewBytes != null) {
      final thumbPath = '$profileId/${fileName}_thumb.jpg';
      await bucketRef.uploadBinary(
        thumbPath,
        media.previewBytes!,
        fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      thumbnailUrl = bucketRef.getPublicUrl(thumbPath);
    }

    return _UploadResult(
      mediaUrl: publicUrl,
      thumbnailUrl: thumbnailUrl,
    );
  }

  String _buildFilename(String profileId, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${profileId}_$timestamp.$extension';
  }

  /// Recupera momenti entro un raggio specificato da coordinate centrali
  /// Usa RPC function con PostGIS ST_DWithin per query spaziale
  Future<List<Moment>> getNearbyMoments({
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
    List<MomentMediaType>? mediaTypes,
    int limit = 200,
  }) async {
    try {
      // Usa la RPC function invece del filter (PostgREST non supporta filtri PostGIS)
      final params = <String, dynamic>{
        'center_lat': centerLat,
        'center_lon': centerLon,
        'radius_meters': radiusMeters,
        'result_limit': limit,
      };

      if (mediaTypes != null && mediaTypes.isNotEmpty) {
        params['media_types'] = mediaTypes.map((type) => type.name).toList();
      }

      final response = await _client.rpc(
        'get_nearby_moments',
        params: params,
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
    List<MomentMediaType>? mediaTypes,
    int limit = 200,
  }) async {
    try {
      // Usa la RPC function invece del filter (PostgREST non supporta filtri PostGIS)
      final params = <String, dynamic>{
        'sw_lat': swLat,
        'sw_lon': swLon,
        'ne_lat': neLat,
        'ne_lon': neLon,
        'result_limit': limit,
      };

      if (mediaTypes != null && mediaTypes.isNotEmpty) {
        params['media_types'] = mediaTypes.map((type) => type.name).toList();
      }

      final response = await _client.rpc(
        'get_moments_in_bounds',
        params: params,
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

  Future<List<Moment>> getMyMoments(String userId) async {
    final response = await _client
        .from('moments')
        .select()
        .eq('profile_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Moment.fromMap(Map<String, dynamic>.from(json)))
        .toList();
  }
}

class _UploadResult {
  _UploadResult({required this.mediaUrl, this.thumbnailUrl});

  final String mediaUrl;
  final String? thumbnailUrl;
}

enum MediaUploadPhase { idle, preparing, uploading, saving, completed }

class MediaUploadProgress {
  MediaUploadProgress({
    required this.phase,
    required this.progress,
  });

  final MediaUploadPhase phase;
  final double progress;
}
