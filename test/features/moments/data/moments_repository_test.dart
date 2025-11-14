import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:placeflex_app/core/constants.dart';
import 'package:placeflex_app/features/moments/data/moments_repository.dart';
import 'package:placeflex_app/features/moments/data/prepared_moment_media.dart';
import 'package:placeflex_app/features/moments/models/moment.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockSupabaseStorageClient extends Mock
    implements SupabaseStorageClient {}

class _MockStorageFileApi extends Mock implements StorageFileApi {}

class _MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {}

class _MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

void main() {
  late _MockSupabaseClient client;
  late _MockSupabaseStorageClient storageClient;
  late _MockStorageFileApi fileApi;
  late _MockSupabaseQueryBuilder queryBuilder;
  late _MockPostgrestFilterBuilder filterBuilder;
  late _MockPostgrestTransformBuilder<PostgrestList> selectBuilder;
  late _MockPostgrestTransformBuilder<PostgrestMap?> maybeSingleBuilder;

  setUpAll(() {
    registerFallbackValue(FileOptions(contentType: 'image/jpeg'));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    client = _MockSupabaseClient();
    storageClient = _MockSupabaseStorageClient();
    fileApi = _MockStorageFileApi();
    queryBuilder = _MockSupabaseQueryBuilder();
    filterBuilder = _MockPostgrestFilterBuilder();
    selectBuilder = _MockPostgrestTransformBuilder<PostgrestList>();
    maybeSingleBuilder = _MockPostgrestTransformBuilder<PostgrestMap?>();

    when(() => client.storage).thenReturn(storageClient);
    when(
      () => storageClient.from(AppConstants.momentsBucket),
    ).thenReturn(fileApi);
    when(
      () => fileApi.uploadBinary(
        any(),
        any(),
        fileOptions: any(named: 'fileOptions'),
      ),
    ).thenAnswer((_) async => 'upload-id');
    when(
      () => fileApi.getPublicUrl(any()),
    ).thenReturn('https://cdn.placeflex.test/path.png');
    when(() => client.from('moments')).thenAnswer((_) => queryBuilder);
    when(() => queryBuilder.insert(any())).thenAnswer((_) => filterBuilder);
    when(() => filterBuilder.select()).thenAnswer((_) => selectBuilder);
    when(() => filterBuilder.select(any())).thenAnswer((_) => selectBuilder);
    when(
      () => selectBuilder.maybeSingle(),
    ).thenAnswer((_) => maybeSingleBuilder);
  });

  group('createMoment', () {
    test('uploads media and persists payload for photo moments', () async {
      late Map<String, dynamic> payload;
      late String uploadedPath;
      late FileOptions? uploadedOptions;

      when(() => queryBuilder.insert(any())).thenAnswer((invocation) {
        payload = Map<String, dynamic>.from(
          invocation.positionalArguments.first as Map,
        );
        return filterBuilder;
      });

      _stubFutureOnBuilder(
        builder: maybeSingleBuilder,
        result: {
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
        },
      );

      when(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenAnswer((invocation) async {
        uploadedPath = invocation.positionalArguments.first as String;
        uploadedOptions =
            invocation.namedArguments[#fileOptions] as FileOptions?;
        return 'upload-id';
      });

      final repository = MomentsRepository(client: client);
      final preparedMedia = PreparedMomentMedia(
        type: MomentMediaType.photo,
        bytes: Uint8List.fromList([1, 2, 3]),
        extension: 'jpg',
        contentType: 'image/jpeg',
        sizeBytes: 3,
      );

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
          preparedMedia: preparedMedia,
          mediaSizeBytes: preparedMedia.sizeBytes,
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
      expect(payload['media_size_bytes'], 3);
      expect(payload['media_duration_ms'], isNull);
      expect(payload['visibility'], 'public');
      expect(payload['media_processing_status'], 'ready');
      expect(payload['location'], {
        'type': 'Point',
        'coordinates': [12.4923, 41.8902],
      });

      expect(uploadedPath, startsWith('profile-1/'));
      expect(uploadedPath, endsWith('.jpg'));
      expect(uploadedOptions?.contentType, 'image/jpeg');

      verify(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).called(1);
      verify(() => fileApi.getPublicUrl(uploadedPath)).called(1);
    });

    test('skips upload for text-only moments', () async {
      _stubFutureOnBuilder(
        builder: maybeSingleBuilder,
        result: {
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
        },
      );

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

      verifyNever(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      );
    });
  });

  group('spatial queries', () {
    late _MockPostgrestFilterBuilder rpcBuilder;

    setUp(() {
      rpcBuilder = _MockPostgrestFilterBuilder();
      when(
        () => client.rpc(any(), params: any(named: 'params')),
      ).thenAnswer((_) => rpcBuilder);
      _stubFutureOnFilterBuilder(
        builder: rpcBuilder,
        result: [
          _momentRow(),
        ],
      );
    });

    test('getMomentsInBounds passes server-side filters when provided', () async {
      final repository = MomentsRepository(client: client);

      final result = await repository.getMomentsInBounds(
        swLat: 45.0,
        swLon: 9.0,
        neLat: 46.0,
        neLon: 10.0,
        mediaTypes: const [
          MomentMediaType.video,
          MomentMediaType.photo,
        ],
        limit: 50,
      );

      expect(result, isNotEmpty);
      final verification = verify(
        () => client.rpc(
          'get_moments_in_bounds',
          params: captureAny(named: 'params'),
        ),
      );
      final params =
          Map<String, dynamic>.from(verification.captured.first as Map);
      expect(params['result_limit'], 50);
      expect(
        params['media_types'],
        containsAllInOrder(['video', 'photo']),
      );
    });

    test('getNearbyMoments omits filters when not needed', () async {
      final repository = MomentsRepository(client: client);

      final result = await repository.getNearbyMoments(
        centerLat: 45.0,
        centerLon: 9.0,
        radiusMeters: 1000,
      );

      expect(result, isNotEmpty);
      final verification = verify(
        () => client.rpc(
          'get_nearby_moments',
          params: captureAny(named: 'params'),
        ),
      );
      final params =
          Map<String, dynamic>.from(verification.captured.first as Map);
      expect(params.containsKey('media_types'), isFalse);
      expect(params['radius_meters'], 1000);
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

void _stubFutureOnBuilder<T>({
  required _MockPostgrestTransformBuilder<T> builder,
  required T result,
}) {
  when(
    () => builder.then<dynamic>(any(), onError: any(named: 'onError')),
  ).thenAnswer((invocation) {
    final onValue = invocation.positionalArguments.first as dynamic Function(T);
    final onError = invocation.namedArguments[#onError] as Function?;
    return Future<T>.value(result).then(onValue, onError: onError);
  });

  when(() => builder.catchError(any(), test: any(named: 'test'))).thenAnswer((
    invocation,
  ) {
    final handler = invocation.positionalArguments.first as Function;
    final test =
        invocation.namedArguments[#test] as bool Function(Object)? ??
        (_) => true;
    return Future<T>.value(result).catchError(handler, test: test);
  });

  when(
    () => builder.timeout(any(), onTimeout: any(named: 'onTimeout')),
  ).thenAnswer((invocation) {
    final duration = invocation.positionalArguments.first as Duration;
    final onTimeout =
        invocation.namedArguments[#onTimeout] as FutureOr<T> Function()?;
    return Future<T>.value(result).timeout(duration, onTimeout: onTimeout);
  });

  when(() => builder.whenComplete(any())).thenAnswer((invocation) {
    final action = invocation.positionalArguments.first as FutureOr Function();
    return Future<T>.value(result).whenComplete(action);
  });

  when(
    () => builder.asStream(),
  ).thenAnswer((_) => Future<T>.value(result).asStream());
}

void _stubFutureOnFilterBuilder({
  required _MockPostgrestFilterBuilder builder,
  required PostgrestList result,
}) {
  when(
    () => builder.then<dynamic>(any(), onError: any(named: 'onError')),
  ).thenAnswer((invocation) {
    final onValue = invocation.positionalArguments.first as dynamic Function(
      PostgrestList,
    );
    final onError = invocation.namedArguments[#onError] as Function?;
    return Future<PostgrestList>.value(result).then(
      onValue,
      onError: onError,
    );
  });

  when(() => builder.catchError(any(), test: any(named: 'test'))).thenAnswer((
    invocation,
  ) {
    final handler = invocation.positionalArguments.first as Function;
    final test =
        invocation.namedArguments[#test] as bool Function(Object)? ??
        (_) => true;
    return Future<PostgrestList>.value(result).catchError(handler, test: test);
  });

  when(
    () => builder.timeout(any(), onTimeout: any(named: 'onTimeout')),
  ).thenAnswer((invocation) {
    final duration = invocation.positionalArguments.first as Duration;
    final onTimeout =
        invocation.namedArguments[#onTimeout]
            as FutureOr<PostgrestList> Function()?;
    return Future<PostgrestList>.value(result)
        .timeout(duration, onTimeout: onTimeout);
  });

  when(() => builder.whenComplete(any())).thenAnswer((invocation) {
    final action = invocation.positionalArguments.first as FutureOr Function();
    return Future<PostgrestList>.value(result).whenComplete(action);
  });

  when(
    () => builder.asStream(),
  ).thenAnswer((_) => Future<PostgrestList>.value(result).asStream());
}

Map<String, dynamic> _momentRow({
  String id = 'moment-1',
  String mediaType = 'photo',
  double lon = 12.5,
  double lat = 41.9,
}) {
  return {
    'id': id,
    'profile_id': 'profile-1',
    'title': 'Sample',
    'description': null,
    'media_type': mediaType,
    'media_url': null,
    'thumbnail_url': null,
    'tags': [],
    'visibility': 'public',
    'status': 'published',
    'radius_m': 100,
    'location': {
      'type': 'Point',
      'coordinates': [lon, lat],
    },
    'created_at': DateTime.utc(2024, 1, 1).toIso8601String(),
    'updated_at': DateTime.utc(2024, 1, 1).toIso8601String(),
  };
}
