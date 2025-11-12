class UserProfile {
  UserProfile({
    required this.id,
    this.displayName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.role,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? displayName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final String? role;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String,
      displayName: data['display_name'] as String?,
      username: data['username'] as String?,
      bio: data['bio'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      role: data['role'] as String?,
      metadata: (data['metadata'] as Map?)?.cast<String, dynamic>(),
      createdAt: data['created_at'] == null
          ? null
          : DateTime.tryParse(data['created_at'] as String),
      updatedAt: data['updated_at'] == null
          ? null
          : DateTime.tryParse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toUpdatePayload() {
    final payload = <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
    };

    payload.removeWhere((key, value) => value == null);
    return payload;
  }

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? role,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
