import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:placeflex_app/core/constants.dart';
import 'package:placeflex_app/features/moments/data/moments_repository.dart';
import 'package:placeflex_app/features/moments/models/moment.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class _MockStorageFileApi extends Mock implements StorageFileApi {}

class _MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<Map<String, dynamic>> {}

void main() {
  late _MockSupabaseClient client;
  late _MockSupabaseStorageClient storageClient;
  late _MockStorageFileApi fileApi;
  late _MockSupabaseQueryBuilder queryBuilder;
  late _MockPostgrestFilterBuilder filterBuilder;

  setUpAll(() {
    registerFallbackValue(BucketOptions(public: true));
    registerFallbackValue(FileOptions(contentType: 'image/jpeg'));
  });

  setUp(() {
    client = _MockSupabaseClient();
    storageClient = _MockSupabaseStorageClient();
    fileApi = _MockStorageFileApi();
    queryBuilder = _MockSupabaseQueryBuilder();
    filterBuilder = _MockPostgrestFilterBuilder();

    when(() => client.storage).thenReturn(storageClient);
    when(() => storageClient.from(AppConstants.momentsBucket)).thenReturn(fileApi);
    when(() => storageClient.createBucket(any(), any())).thenAnswer((_) async {});
    when(() => fileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')))
        .thenAnswer((_) async {});
    when(() => fileApi.getPublicUrl(any())).thenReturn('https://cdn.placeflex.test/path.png');
    when(() => client.from('moments')).thenReturn(queryBuilder);
    when(() => queryBuilder.insert(any())).thenReturn(filterBuilder);
    when(() => filterBuilder.select()).thenReturn(filterBuilder);
  });

  group('createMoment', () {
    test('uploads media and persists payload for photo moments', () async {
      late Map<String, dynamic> payload;
      late String uploadedPath;
      late FileOptions? uploadedOptions;

      when(() => queryBuilder.insert(any())).thenAnswer((invocation) {
        payload = Map<String, dynamic>.from(invocation.positionalArguments.first as Map);
        return filterBuilder;
      });

      when(() => fileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')))
          .thenAnswer((invocation) async {
        uploadedPath = invocation.positionalArguments.first as String;
        uploadedOptions = invocation.namedArguments[#fileOptions] as FileOptions?;
      });

      when(() => filterBuilder.maybeSingle()).thenAnswer((_) async {
        return {
          'id': '123',
          'profile_id': 'profile-1',
          'title': 'Duomo Sunset',
          'description': 'Magic hour over Milan',
          'media_type': 'photo',
          'media_url': 'https://cdn.placeflex.test/path.png',
          'thumbnail_url': null,
          'tags': ['tramonto'],
          'visibility': 'public',
          'status': 'published',
          'radius_m': 100,
          'location': {
            'type': 'Point',
            'coordinates': [12.4923, 41.8902],
          },
          'created_at': DateTime.utc(2024, 1, 1).toIso8601String(),
          'updated_at': DateTime.utc(2024, 1, 1).toIso8601String(),
        };
      });

      final repository = MomentsRepository(client: client);

      final result = await repository.createMoment(
        CreateMomentInput(
          profileId: 'profile-1',
          title: 'Duomo Sunset',
          description: 'Magic hour over Milan',
          mediaType: MomentMediaType.photo,
          mediaFile: XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: 'tramonto.png',
            mimeType: 'image/png',
          ),
          mediaBytes: Uint8List.fromList([1, 2, 3]),
          visibility: MomentVisibility.public,
          latitude: 41.8902,
          longitude: 12.4923,
          tags: const ['tramonto'],
        ),
      );

      expect(result.id, '123');
      expect(result.mediaType, MomentMediaType.photo);
      expect(result.mediaUrl, 'https://cdn.placeflex.test/path.png');

      expect(payload['profile_id'], 'profile-1');
      expect(payload['media_type'], 'photo');
      expect(payload['visibility'], 'public');
      expect(payload['location'], {
        'type': 'Point',
        'coordinates': [12.4923, 41.8902],
      });

      expect(uploadedPath, startsWith('profile-1/'));
      expect(uploadedPath, endsWith('.png'));
      expect(uploadedOptions?.contentType, 'image/png');

      verify(() => storageClient.createBucket(AppConstants.momentsBucket, any())).called(1);
      verify(() => fileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')))
          .called(1);
      verify(() => fileApi.getPublicUrl(uploadedPath)).called(1);
    });

    test('skips upload for text-only moments', () async {
      when(() => filterBuilder.maybeSingle()).thenAnswer((_) async {
        return {
          'id': 'abc',
          'profile_id': 'profile-2',
          'title': 'Solo testo',
          'description': null,
          'media_type': 'text',
          'media_url': null,
          'thumbnail_url': null,
          'tags': [],
          'visibility': 'private',
          'status': 'published',
          'radius_m': 200,
          'location': {
            'type': 'Point',
            'coordinates': [9.19, 45.46],
          },
          'created_at': DateTime.utc(2024, 5, 4).toIso8601String(),
          'updated_at': DateTime.utc(2024, 5, 4).toIso8601String(),
        };
      });

      final repository = MomentsRepository(client: client);

      final result = await repository.createMoment(
        CreateMomentInput(
          profileId: 'profile-2',
          title: 'Solo testo',
          mediaType: MomentMediaType.text,
          visibility: MomentVisibility.private,
          latitude: 45.46,
          longitude: 9.19,
        ),
      );

      expect(result.mediaType, MomentMediaType.text);
      expect(result.mediaUrl, isNull);

      verifyNever(() => fileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')));
    });
  });

  group('Moment.fromMap', () {
    test('parses coordinates preserving longitude latitude order', () {
      final map = {
        'id': 'm-1',
        'profile_id': 'p-1',
        'title': 'Test',
        'description': null,
        'media_type': 'photo',
        'media_url': 'https://cdn.test/m-1.jpg',
        'thumbnail_url': null,
        'tags': ['tag'],
        'visibility': 'public',
        'status': 'published',
        'radius_m': 150,
        'location': {
          'type': 'Point',
          'coordinates': [12.5, 41.9],
        },
        'created_at': '2024-01-01T12:00:00.000Z',
        'updated_at': '2024-01-02T12:00:00.000Z',
      };

      final moment = Moment.fromMap(map);

      expect(moment.longitude, 12.5);
      expect(moment.latitude, 41.9);
      expect(moment.tags, ['tag']);
    });
  });
}
