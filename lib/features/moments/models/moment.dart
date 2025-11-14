enum MomentMediaType { photo, video, audio, text }

enum MomentVisibility { public, private }

enum MomentStatus { draft, published, flagged, review }

enum MomentMediaProcessingStatus { ready, queued, processing, failed }

MomentMediaType momentMediaTypeFromString(String input) {
  return MomentMediaType.values.firstWhere(
    (type) => type.name == input,
    orElse: () => MomentMediaType.photo,
  );
}

MomentVisibility momentVisibilityFromString(String input) {
  return MomentVisibility.values.firstWhere(
    (type) => type.name == input,
    orElse: () => MomentVisibility.public,
  );
}

MomentStatus momentStatusFromString(String input) {
  return MomentStatus.values.firstWhere(
    (type) => type.name == input,
    orElse: () => MomentStatus.published,
  );
}

MomentMediaProcessingStatus momentMediaProcessingStatusFromString(
  String? input,
) {
  if (input == null) {
    return MomentMediaProcessingStatus.ready;
  }
  return MomentMediaProcessingStatus.values.firstWhere(
    (type) => type.name == input,
    orElse: () => MomentMediaProcessingStatus.ready,
  );
}

class Moment {
  Moment({
    required this.id,
    required this.profileId,
    required this.title,
    this.description,
    required this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaSizeBytes,
    this.mediaDurationMs,
    required this.mediaProcessingStatus,
    this.mediaProcessingError,
    this.tags = const [],
    required this.visibility,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String title;
  final String? description;
  final MomentMediaType mediaType;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int? mediaSizeBytes;
  final int? mediaDurationMs;
  final MomentMediaProcessingStatus mediaProcessingStatus;
  final String? mediaProcessingError;
  final List<String> tags;
  final MomentVisibility visibility;
  final MomentStatus status;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Moment.fromMap(Map<String, dynamic> map) {
    final location = map['location'] as Map<String, dynamic>?;
    final coordinates = location != null
        ? (location['coordinates'] as List?)?.cast<num>()
        : null;

    var lon = 0.0;
    var lat = 0.0;
    if (coordinates != null) {
      if (coordinates.isNotEmpty) {
        lon = coordinates[0].toDouble();
      }
      if (coordinates.length >= 2) {
        lat = coordinates[1].toDouble();
      }
    }

    return Moment(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      mediaType: momentMediaTypeFromString(map['media_type'] as String),
      mediaUrl: map['media_url'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      mediaSizeBytes: (map['media_size_bytes'] as num?)?.toInt(),
      mediaDurationMs: (map['media_duration_ms'] as num?)?.toInt(),
      mediaProcessingStatus: momentMediaProcessingStatusFromString(
        map['media_processing_status'] as String?,
      ),
      mediaProcessingError: map['media_processing_error'] as String?,
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      visibility: momentVisibilityFromString(map['visibility'] as String),
      status: momentStatusFromString(map['status'] as String),
      latitude: lat,
      longitude: lon,
      radiusMeters: (map['radius_m'] as num?)?.toInt() ?? 100,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
