import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<UserProfile> getOrCreateProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response != null) {
      return UserProfile.fromMap(Map<String, dynamic>.from(response));
    }

    final inserted = await _client
        .from('profiles')
        .upsert({
          'id': userId,
          'display_name': null,
        })
        .select()
        .maybeSingle();

    if (inserted == null) {
      throw StateError('Impossibile creare il profilo utente.');
    }

    return UserProfile.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final payload = profile.toUpdatePayload();

    final result = await _client
        .from('profiles')
        .upsert(payload)
        .select()
        .maybeSingle();

    if (result == null) {
      throw StateError('Aggiornamento profilo non riuscito.');
    }

    return UserProfile.fromMap(Map<String, dynamic>.from(result));
  }
}
