import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/theme/colors_2026.dart';
import '../../../core/theme/spacing_2026.dart';
import '../../moments/data/moments_repository.dart';
import '../../moments/models/moment.dart';
import '../../moments/presentation/create_moment_page_2026.dart';
import 'widgets/moment_details_sheet.dart';
import 'widgets/moment_marker_icon.dart';

class _CachedIcon {
  _CachedIcon({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// MapScreen 2026 - Mappa interattiva con momenti nearby
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  CircleAnnotationManager? _userLocationManager;
  geo.Position? _currentPosition;
  List<Moment> _nearbyMoments = [];
  bool _isLoading = true;
  bool _isViewportLoading = false;
  String? _errorMessage;
  Timer? _markerRefreshDebounce;
  StreamSubscription<geo.Position>? _positionStream;
  bool _isFetchingViewport = false;
  bool _pendingForcedViewportFetch = false;
  DateTime? _lastViewportFetch;

  // Clustering state
  double _currentZoom = _defaultZoom;
  final bool _isClusteringEnabled = true;
  static const _clusterZoomThreshold =
      13.0; // Sotto questo zoom, attiva clustering


  // Filtri per tipo media
  final Map<MomentMediaType, bool> _typeFilters = {
    MomentMediaType.photo: true,
    MomentMediaType.video: true,
    MomentMediaType.audio: true,
    MomentMediaType.text: true,
  };

  final _momentsRepository = MomentsRepository();
  final Map<String, _CachedIcon> _markerIconCache =
      <String, _CachedIcon>{};
  final Map<String, _CachedIcon> _clusterIconCache =
      <String, _CachedIcon>{};
  final Set<String> _styleImageKeys = {};
  final Map<String, PointAnnotation> _momentAnnotations = {};
  final Map<String, String> _annotationToMomentId = {};
  final Map<String, List<Moment>> _clusterAnnotationData = {};

  // Default: Milano centro (fallback se location negato)
  static const _defaultLat = 45.4642;
  static const _defaultLon = 9.1900;
  static const _defaultZoom = 14.0;
  static const _nearbyRadiusMeters = 5000.0; // 5km
  static const _viewportFetchThrottle = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _markerRefreshDebounce?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Controlla e richiedi permessi
      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Permessi location negati permanentemente');
      }

      if (permission == geo.LocationPermission.denied) {
        // Usa fallback Milano
        await _loadMomentsForLocation(_defaultLat, _defaultLon);
        return;
      }

      // Ottieni posizione corrente
      _currentPosition = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      await _loadMomentsForLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore caricamento posizione: $e';
        _isLoading = false;
      });
      // Fallback Milano
      await _loadMomentsForLocation(_defaultLat, _defaultLon);
    }
  }

  Future<void> _loadMomentsForLocation(double lat, double lon) async {
    try {
      final filters = _selectedMediaFilters();
      final moments = await _momentsRepository.getNearbyMoments(
        centerLat: lat,
        centerLon: lon,
        radiusMeters: _nearbyRadiusMeters,
        mediaTypes: filters,
      );

      setState(() {
        _nearbyMoments = moments;
        _isLoading = false;
        _errorMessage = null;
      });

      // Visualizza marker sulla mappa
      await _displayMomentsOnMap();
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore caricamento momenti: $e';
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _centerMapOnPosition();
    _initializeAnnotationManager();
    _initializeUserLocationMarker();
    _styleImageKeys.clear();
    unawaited(_registerCachedStyleImages());
    unawaited(_fetchMomentsForCurrentViewport(force: true));
  }

  Future<void> _initializeAnnotationManager() async {
    if (_mapboxMap == null) return;

    _annotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();

    // Listener per tap sui marker
    _annotationManager!.addOnPointAnnotationClickListener(
      _AnnotationClickListener(onAnnotationClick: _handleMarkerTap),
    );

    // Visualizza marker se ci sono già momenti caricati
    if (_nearbyMoments.isNotEmpty) {
      await _displayMomentsOnMap();
    }
  }

  Future<void> _initializeUserLocationMarker() async {
    if (_mapboxMap == null) return;

    // Crea circle annotation manager per user location
    _userLocationManager = await _mapboxMap!.annotations
        .createCircleAnnotationManager();

    // Mostra posizione corrente se disponibile
    if (_currentPosition != null) {
      await _updateUserLocationMarker(_currentPosition!);
    }

    // Setup real-time position stream
    _positionStream =
        geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 10, // Update ogni 10 metri
          ),
        ).listen((position) {
          _currentPosition = position;
          _updateUserLocationMarker(position);
        });

    debugPrint('📍 User location marker inizializzato con stream');
  }

  Future<void> _updateUserLocationMarker(geo.Position position) async {
    if (_userLocationManager == null) return;

    // Cancella marker precedenti
    await _userLocationManager!.deleteAll();

    // Crea circle blu pulsante per user location
    final userLocationCircle = CircleAnnotationOptions(
      geometry: Point(
        coordinates: Position(position.longitude, position.latitude),
      ),
      circleRadius: 12.0,
      circleColor: Colors.blue.value,
      circleOpacity: 0.8,
      circleStrokeWidth: 3.0,
      circleStrokeColor: Colors.white.value,
      circleStrokeOpacity: 1.0,
    );

    // Accuracy circle (semi-trasparente)
    final accuracyCircle = CircleAnnotationOptions(
      geometry: Point(
        coordinates: Position(position.longitude, position.latitude),
      ),
      circleRadius: position.accuracy, // Radius basato su GPS accuracy
      circleColor: Colors.blue.withOpacity(0.1).value,
      circleOpacity: 0.3,
      circleStrokeWidth: 1.0,
      circleStrokeColor: Colors.blue.withOpacity(0.3).value,
    );

    await _userLocationManager!.createMulti([
      accuracyCircle,
      userLocationCircle,
    ]);

    debugPrint(
      '📍 User location updated: ${position.latitude}, ${position.longitude}, accuracy: ${position.accuracy}m',
    );
  }

  Future<void> _handleMarkerTap(PointAnnotation annotation) async {
    final clusterMoments = _clusterAnnotationData[annotation.id];
    if (clusterMoments != null && clusterMoments.length > 1) {
      await _zoomToCluster(clusterMoments);
      return;
    }

    final momentId = _annotationToMomentId[annotation.id];
    if (momentId == null) return;

    Moment? tappedMoment;
    for (final moment in _nearbyMoments) {
      if (moment.id == momentId) {
        tappedMoment = moment;
        break;
      }
    }

    if (tappedMoment == null) return;

    await _playMarkerTapFeedback(annotation);
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MomentDetailsSheet(moment: tappedMoment!),
    );
  }

  Future<void> _zoomToCluster(List<Moment> clusterMoments) async {
    if (_mapboxMap == null || clusterMoments.isEmpty) return;

    // Calcola bounds del cluster
    double minLat = clusterMoments.first.latitude;
    double maxLat = clusterMoments.first.latitude;
    double minLon = clusterMoments.first.longitude;
    double maxLon = clusterMoments.first.longitude;

    for (final moment in clusterMoments) {
      if (moment.latitude < minLat) minLat = moment.latitude;
      if (moment.latitude > maxLat) maxLat = moment.latitude;
      if (moment.longitude < minLon) minLon = moment.longitude;
      if (moment.longitude > maxLon) maxLon = moment.longitude;
    }

    // Calcola centro e zoom appropriato
    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;

    // Calcola distanza per determinare zoom (approssimativo)
    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    // Zoom level basato su span (empirico)
    double targetZoom = _clusterZoomThreshold + 2.0; // Default sopra threshold
    if (maxDiff < 0.001) {
      targetZoom = 17.0; // Molto vicini
    } else if (maxDiff < 0.005) {
      targetZoom = 15.0; // Vicini
    } else if (maxDiff < 0.01) {
      targetZoom = 14.0; // Media distanza
    }

    // Anima camera verso il cluster
    final cameraOptions = CameraOptions(
      center: Point(coordinates: Position(centerLon, centerLat)),
      zoom: targetZoom,
      padding: MbxEdgeInsets(top: 100, left: 50, bottom: 100, right: 50),
    );

    await _mapboxMap!.flyTo(
      cameraOptions,
      MapAnimationOptions(duration: 800, startDelay: 0),
    );

    debugPrint(
      '🎯 Zoom to cluster: ${clusterMoments.length} momenti, target zoom: $targetZoom',
    );
  }

  List<MomentMediaType>? _selectedMediaFilters() {
    final activeTypes = _typeFilters.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (activeTypes.length == _typeFilters.length) {
      return null;
    }
    return activeTypes;
  }

  Future<void> _registerCachedStyleImages() async {
    if (_mapboxMap == null) return;
    for (final entry in _markerIconCache.entries) {
      await _addStyleImage(entry.key, entry.value);
    }
    for (final entry in _clusterIconCache.entries) {
      await _addStyleImage(entry.key, entry.value);
    }
  }

  Future<void> _addStyleImage(String imageId, _CachedIcon icon) async {
    if (_mapboxMap == null || _styleImageKeys.contains(imageId)) {
      return;
    }
    final mbxImage = MbxImage(
      width: icon.width,
      height: icon.height,
      data: icon.bytes,
    );
    try {
      await _mapboxMap!.style.addStyleImage(
        imageId,
        1.0,
        mbxImage,
        false,
        const [],
        const [],
        null,
      );
      _styleImageKeys.add(imageId);
    } catch (error) {
      _styleImageKeys.add(imageId);
    }
  }

  Future<String> _getMarkerIconId(
    MomentMediaType type,
    bool isDark,
  ) async {
    final key = 'marker-${type.name}-${isDark ? 'dark' : 'light'}';
    var cached = _markerIconCache[key];
    if (cached == null) {
      final bytes = await MomentMarkerIcon.createMarkerForType(
        mediaType: type,
        isDark: isDark,
      );
      cached = _CachedIcon(bytes: bytes, width: 56, height: 56);
      _markerIconCache[key] = cached;
    }
    await _addStyleImage(key, cached);
    return key;
  }

  Future<String> _getClusterIconId(int count, bool isDark) async {
    final label = count > 99 ? '99+' : count.toString();
    final key = 'cluster-${isDark ? 'dark' : 'light'}-$label';
    var cached = _clusterIconCache[key];
    if (cached == null) {
      final bytes = await MomentMarkerIcon.createClusterMarker(
        count: count,
        isDark: isDark,
      );
      cached = _CachedIcon(bytes: bytes, width: 64, height: 64);
      _clusterIconCache[key] = cached;
    }
    await _addStyleImage(key, cached);
    return key;
  }

  void _onStyleLoaded(StyleLoadedEventData event) {
    _styleImageKeys.clear();
    unawaited(_registerCachedStyleImages());
    unawaited(_displayMomentsOnMap());
  }

  void _handleCameraChanged(CameraChangedEventData event) {
    final newZoom = event.cameraState.zoom;
    if ((newZoom - _currentZoom).abs() < 0.05) {
      return;
    }
    _currentZoom = newZoom;
    _markerRefreshDebounce?.cancel();
    _markerRefreshDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      unawaited(_displayMomentsOnMap());
    });
  }

  void _handleMapIdle(MapIdleEventData event) {
    unawaited(_fetchMomentsForCurrentViewport());
  }

  Future<void> _fetchMomentsForCurrentViewport({bool force = false}) async {
    if (_mapboxMap == null) return;

    if (_isFetchingViewport) {
      if (force) {
        _pendingForcedViewportFetch = true;
      }
      return;
    }

    if (!force &&
        _lastViewportFetch != null &&
        DateTime.now().difference(_lastViewportFetch!) <
            _viewportFetchThrottle) {
      return;
    }

    _isFetchingViewport = true;
    if (mounted) {
      setState(() {
        _isViewportLoading = true;
      });
    }

    try {
      final cameraState = await _mapboxMap!.getCameraState();
      final bounds = await _mapboxMap!
          .coordinateBoundsForCameraUnwrapped(
        cameraState.toCameraOptions(),
      );
      final expandedBounds = _expandBounds(bounds, paddingFactor: 0.15);
      final filters = _selectedMediaFilters();

      final moments = await _momentsRepository.getMomentsInBounds(
        swLat: expandedBounds.southwest.coordinates.lat.toDouble(),
        swLon: expandedBounds.southwest.coordinates.lng.toDouble(),
        neLat: expandedBounds.northeast.coordinates.lat.toDouble(),
        neLon: expandedBounds.northeast.coordinates.lng.toDouble(),
        mediaTypes: filters,
      );

      if (!mounted) return;

      setState(() {
        _nearbyMoments = moments;
        _errorMessage = null;
        _isViewportLoading = false;
      });
      _lastViewportFetch = DateTime.now();
      await _displayMomentsOnMap();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isViewportLoading = false;
          _errorMessage = 'Errore caricamento momenti: $error';
        });
      }
    } finally {
      _isFetchingViewport = false;
      if (_pendingForcedViewportFetch) {
        _pendingForcedViewportFetch = false;
        unawaited(_fetchMomentsForCurrentViewport(force: true));
      }
    }
  }

  CoordinateBounds _expandBounds(
    CoordinateBounds bounds, {
    double paddingFactor = 0.1,
  }) {
    final sw = bounds.southwest.coordinates;
    final ne = bounds.northeast.coordinates;

    final latSpan = (ne.lat - sw.lat).abs();
    final lonSpan = (ne.lng - sw.lng).abs();

    final latPadding = latSpan * paddingFactor;
    final lonPadding = lonSpan * paddingFactor;

    return CoordinateBounds(
      southwest: Point(
        coordinates: Position(sw.lng - lonPadding, sw.lat - latPadding),
      ),
      northeast: Point(
        coordinates: Position(ne.lng + lonPadding, ne.lat + latPadding),
      ),
      infiniteBounds: false,
    );
  }

  Future<void> _displayMomentsOnMap() async {
    if (_mapboxMap == null || _annotationManager == null) return;
    if (_nearbyMoments.isEmpty) return;

    try {
      // Cancella marker e mappe locali
      await _annotationManager!.deleteAll();
      _momentAnnotations.clear();
      _annotationToMomentId.clear();
      _clusterAnnotationData.clear();

      final isDark = Theme.of(context).brightness == Brightness.dark;

      // Filtra momenti per tipo media attivo
      final filteredMoments = _nearbyMoments.where((moment) {
        return _typeFilters[moment.mediaType] ?? true;
      }).toList();

      if (filteredMoments.isEmpty) return;

      // Determina se usare clustering in base allo zoom
      final shouldCluster =
          _currentZoom < _clusterZoomThreshold &&
          _isClusteringEnabled &&
          filteredMoments.length > 10;

      if (shouldCluster) {
        await _displayClusters(filteredMoments, isDark);
      } else {
        await _displayIndividualMarkers(filteredMoments, isDark);
      }

      debugPrint(
        '✅ Visualizzati ${filteredMoments.length} momenti (clustering: $shouldCluster)',
      );
    } catch (e) {
      debugPrint('❌ Errore visualizzazione marker: $e');
      setState(() {
        _errorMessage = 'Errore visualizzazione marker: $e';
      });
    }
  }

  Future<void> _displayIndividualMarkers(
    List<Moment> moments,
    bool isDark, {
    bool clearExisting = false,
  }) async {
    if (_annotationManager == null || moments.isEmpty) {
      return;
    }

    if (clearExisting) {
      _momentAnnotations.clear();
      _annotationToMomentId.clear();
    }

    final requiredTypes = moments.map((m) => m.mediaType).toSet();
    final iconIds = <MomentMediaType, String>{};
    for (final type in requiredTypes) {
      iconIds[type] = await _getMarkerIconId(type, isDark);
    }

    final options = moments.map((moment) {
      final iconId = iconIds[moment.mediaType]!;
      return PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(moment.longitude, moment.latitude),
        ),
        iconImage: iconId,
        iconSize: 0.9,
        iconAnchor: IconAnchor.CENTER,
      );
    }).toList();

    final annotations = await _annotationManager!.createMulti(options);
    for (var i = 0; i < annotations.length; i++) {
      final annotation = annotations[i];
      if (annotation == null) continue;
      final moment = moments[i];
      _momentAnnotations[moment.id] = annotation;
      _annotationToMomentId[annotation.id] = moment.id;
      _animateMarkerEntrance(annotation);
    }
  }

  Future<void> _displayClusters(List<Moment> moments, bool isDark) async {
    final clusters = _createClusters(moments);
    final singletonMoments = <Moment>[];
    final clusterOptions = <PointAnnotationOptions>[];
    final clusterMomentsReference = <List<Moment>>[];

    for (final cluster in clusters) {
      if (cluster.moments.length == 1) {
        singletonMoments.add(cluster.moments.first);
        continue;
      }

      final iconId = await _getClusterIconId(cluster.moments.length, isDark);
      clusterOptions.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(cluster.centerLon, cluster.centerLat),
          ),
          iconImage: iconId,
          iconAnchor: IconAnchor.CENTER,
          iconSize: 1.0,
        ),
      );
      clusterMomentsReference.add(cluster.moments);
    }

    final createdClusters = await _annotationManager!.createMulti(
      clusterOptions,
    );

    for (var i = 0; i < createdClusters.length; i++) {
      final annotation = createdClusters[i];
      if (annotation == null) continue;
      _clusterAnnotationData[annotation.id] = clusterMomentsReference[i];
    }

    if (singletonMoments.isNotEmpty) {
      await _displayIndividualMarkers(
        singletonMoments,
        isDark,
        clearExisting: false,
      );
    }
  }

  Future<void> _animateMarkerEntrance(PointAnnotation annotation) async {
    if (_annotationManager == null) return;
    try {
      annotation.iconSize = 1.15;
      await _annotationManager!.update(annotation);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      annotation.iconSize = 1.0;
      await _annotationManager!.update(annotation);
    } catch (_) {}
  }

  Future<void> _playMarkerTapFeedback(PointAnnotation annotation) async {
    if (_annotationManager == null) return;
    try {
      annotation.iconSize = 1.2;
      await _annotationManager!.update(annotation);
      await Future<void>.delayed(const Duration(milliseconds: 160));
      annotation.iconSize = 1.0;
      await _annotationManager!.update(annotation);
    } catch (_) {}
  }

  List<_MomentCluster> _createClusters(List<Moment> moments) {
    // Clustering basato su griglia (semplificato)
    // Divide la mappa in celle e raggruppa momenti nella stessa cella
    final gridSize = 0.005; // ~500m per cella a lat medio
    final clusters = <String, _MomentCluster>{};

    for (final moment in moments) {
      final cellLat = (moment.latitude / gridSize).floor() * gridSize;
      final cellLon = (moment.longitude / gridSize).floor() * gridSize;
      final cellKey = '$cellLat,$cellLon';

      if (clusters.containsKey(cellKey)) {
        clusters[cellKey]!.moments.add(moment);
        // Ricalcola centro
        clusters[cellKey]!._updateCenter();
      } else {
        clusters[cellKey] = _MomentCluster(
          centerLat: moment.latitude,
          centerLon: moment.longitude,
          moments: [moment],
        );
      }
    }

    return clusters.values.toList();
  }

  Future<void> _centerMapOnPosition() async {
    if (_mapboxMap == null) return;

    final lat = _currentPosition?.latitude ?? _defaultLat;
    final lon = _currentPosition?.longitude ?? _defaultLon;

    final cameraOptions = CameraOptions(
      center: Point(coordinates: Position(lon, lat)),
      zoom: _defaultZoom,
    );

    await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
  }

  Future<void> _recenterMap() async {
    if (_currentPosition != null) {
      await _centerMapOnPosition();
    } else {
      await _initializeLocation();
    }
  }

  Future<void> _createMoment() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendere il rilevamento della posizione...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateMomentPage2026(initialPosition: _currentPosition),
      ),
    );

    // Se è stato creato un momento, ricarica la mappa
    if (result == true && _currentPosition != null) {
      await _loadMomentsForLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

    if (mapboxToken.isEmpty || mapboxToken == 'YOUR_MAPBOX_TOKEN_HERE') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing2026.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: AppColors2026.warning,
                ),
                const SizedBox(height: AppSpacing2026.md),
                Text(
                  'Token Mapbox mancante',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing2026.sm),
                Text(
                  'Configura MAPBOX_ACCESS_TOKEN nel file .env',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors2026.textOnDarkSecondary
                        : AppColors2026.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Mappa Mapbox
          MapWidget(
            key: const ValueKey('mapbox_map'),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  _currentPosition?.longitude ?? _defaultLon,
                  _currentPosition?.latitude ?? _defaultLat,
                ),
              ),
              zoom: _defaultZoom,
            ),
            styleUri: isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS,
            textureView: true,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onCameraChangeListener: _handleCameraChanged,
            onMapIdleListener: _handleMapIdle,
          ),

          // Top status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing2026.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing2026.md,
                  vertical: AppSpacing2026.sm,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors2026.surfaceVariantDark.withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  borderRadius: AppRadius2026.roundedXL,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.place_rounded,
                      color: AppColors2026.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing2026.xs),
                    Expanded(
                      child: Text(
                        '${_nearbyMoments.length} momenti nelle vicinanze',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors2026.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (_isViewportLoading)
            Positioned(
              top: AppSpacing2026.xxxl,
              right: AppSpacing2026.md,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing2026.md,
                    vertical: AppSpacing2026.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: AppRadius2026.roundedLG,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing2026.xs),
                      Text(
                        'Aggiornamento area',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // FAB per creare momento
          Positioned(
            bottom: AppSpacing2026.xl + 72,
            right: AppSpacing2026.md,
            child: SafeArea(
              child: FloatingActionButton(
                heroTag: 'map_create_moment',
                onPressed: _createMoment,
                backgroundColor: AppColors2026.secondary,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ),

          // FAB per recenter
          Positioned(
            bottom: AppSpacing2026.xl,
            right: AppSpacing2026.md,
            child: SafeArea(
              child: FloatingActionButton(
                heroTag: 'map_recenter',
                onPressed: _recenterMap,
                backgroundColor: AppColors2026.primary,
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Filtri tipo media
          Positioned(
            bottom: AppSpacing2026.xl,
            left: AppSpacing2026.md,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing2026.xs),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors2026.surfaceVariantDark.withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  borderRadius: AppRadius2026.roundedXL,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilterChip(
                      icon: Icons.photo_camera_rounded,
                      isActive: _typeFilters[MomentMediaType.photo] ?? true,
                      gradient: const [Color(0xFF00FFA3), Color(0xFF0094FF)],
                      onTap: () {
                        setState(() {
                          _typeFilters[MomentMediaType.photo] =
                              !(_typeFilters[MomentMediaType.photo] ?? true);
                        });
                        _displayMomentsOnMap();
                        unawaited(
                          _fetchMomentsForCurrentViewport(force: true),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing2026.xs),
                    _FilterChip(
                      icon: Icons.play_circle_rounded,
                      isActive: _typeFilters[MomentMediaType.video] ?? true,
                      gradient: const [Color(0xFFFF0080), Color(0xFFFF8C00)],
                      onTap: () {
                        setState(() {
                          _typeFilters[MomentMediaType.video] =
                              !(_typeFilters[MomentMediaType.video] ?? true);
                        });
                        _displayMomentsOnMap();
                        unawaited(
                          _fetchMomentsForCurrentViewport(force: true),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing2026.xs),
                    _FilterChip(
                      icon: Icons.mic_rounded,
                      isActive: _typeFilters[MomentMediaType.audio] ?? true,
                      gradient: const [Color(0xFF9D00FF), Color(0xFFFF00F5)],
                      onTap: () {
                        setState(() {
                          _typeFilters[MomentMediaType.audio] =
                              !(_typeFilters[MomentMediaType.audio] ?? true);
                        });
                        _displayMomentsOnMap();
                        unawaited(
                          _fetchMomentsForCurrentViewport(force: true),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing2026.xs),
                    _FilterChip(
                      icon: Icons.text_fields_rounded,
                      isActive: _typeFilters[MomentMediaType.text] ?? true,
                      gradient: const [Color(0xFFFFD700), Color(0xFFFF6B00)],
                      onTap: () {
                        setState(() {
                          _typeFilters[MomentMediaType.text] =
                              !(_typeFilters[MomentMediaType.text] ?? true);
                        });
                        _displayMomentsOnMap();
                        unawaited(
                          _fetchMomentsForCurrentViewport(force: true),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: AppSpacing2026.md,
              right: AppSpacing2026.md,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing2026.md),
                  decoration: BoxDecoration(
                    color: AppColors2026.error,
                    borderRadius: AppRadius2026.roundedXL,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing2026.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Listener per click sui marker
class _AnnotationClickListener extends OnPointAnnotationClickListener {
  _AnnotationClickListener({required this.onAnnotationClick});

  final void Function(PointAnnotation) onAnnotationClick;

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}

/// Cluster di momenti vicini
class _MomentCluster {
  _MomentCluster({
    required this.centerLat,
    required this.centerLon,
    required this.moments,
  });

  double centerLat;
  double centerLon;
  final List<Moment> moments;

  void _updateCenter() {
    if (moments.isEmpty) return;

    double sumLat = 0;
    double sumLon = 0;

    for (final moment in moments) {
      sumLat += moment.latitude;
      sumLon += moment.longitude;
    }

    centerLat = sumLat / moments.length;
    centerLon = sumLon / moments.length;
  }
}

/// Widget chip per filtri tipo media
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.isActive,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing2026.xs),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.grey.withOpacity(0.3),
          borderRadius: AppRadius2026.roundedMD,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}
