import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/theme/colors_2026.dart';
import '../../../core/theme/spacing_2026.dart';
import '../../moments/data/moments_repository.dart';
import '../../moments/models/moment.dart';
import 'widgets/moment_details_sheet.dart';
import 'widgets/moment_marker_icon.dart';

/// MapScreen 2026 - Mappa interattiva con momenti nearby
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  geo.Position? _currentPosition;
  List<Moment> _nearbyMoments = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  // Clustering state
  double _currentZoom = _defaultZoom;
  bool _isClusteringEnabled = true;
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

  // Default: Milano centro (fallback se location negato)
  static const _defaultLat = 45.4642;
  static const _defaultLon = 9.1900;
  static const _defaultZoom = 14.0;
  static const _nearbyRadiusMeters = 5000.0; // 5km

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
      final moments = await _momentsRepository.getNearbyMoments(
        centerLat: lat,
        centerLon: lon,
        radiusMeters: _nearbyRadiusMeters,
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

    // Listener per zoom changes per clustering dinamico
    _setupZoomListener();
  }

  Future<void> _setupZoomListener() async {
    if (_mapboxMap == null) return;

    // Aggiorna zoom ogni 500ms durante pan/zoom
    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_mapboxMap == null) {
        timer.cancel();
        return;
      }

      final cameraState = await _mapboxMap!.getCameraState();
      final newZoom = cameraState.zoom;

      if ((newZoom - _currentZoom).abs() > 0.5) {
        setState(() {
          _currentZoom = newZoom;
        });
        await _displayMomentsOnMap();
      }
    });
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

  void _handleMarkerTap(PointAnnotation annotation) {
    // Trova il momento corrispondente al marker cliccato
    final index = _nearbyMoments.indexWhere((moment) {
      final annotationPos = annotation.geometry.coordinates;
      return (moment.longitude - annotationPos.lng).abs() < 0.0001 &&
          (moment.latitude - annotationPos.lat).abs() < 0.0001;
    });

    if (index != -1) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MomentDetailsSheet(moment: _nearbyMoments[index]),
      );
    }
  }

  Future<void> _displayMomentsOnMap() async {
    if (_mapboxMap == null || _annotationManager == null) return;
    if (_nearbyMoments.isEmpty) return;

    try {
      // Cancella marker esistenti
      await _annotationManager!.deleteAll();

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
    bool isDark,
  ) async {
    // Registra icone per ogni tipo di media
    final iconIds = <MomentMediaType, String>{};
    for (final type in MomentMediaType.values) {
      final iconId =
          'moment-${type.name}-icon-${DateTime.now().millisecondsSinceEpoch}';

      final iconBytes = await MomentMarkerIcon.createMarkerForType(
        mediaType: type,
        isDark: isDark,
      );

      final mbxImage = MbxImage(width: 56, height: 56, data: iconBytes);

      await _mapboxMap!.style.addStyleImage(
        iconId,
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );

      iconIds[type] = iconId;
      debugPrint('🎨 Registrata icona per ${type.name}: $iconId');
    }

    // Aggiungi marker per ogni momento
    final options = moments.map((moment) {
      final iconId =
          iconIds[moment.mediaType] ?? iconIds[MomentMediaType.photo]!;

      debugPrint(
        '📍 Marker per momento ${moment.id}: tipo=${moment.mediaType.name}, icona=$iconId',
      );

      return PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(moment.longitude, moment.latitude),
        ),
        iconImage: iconId,
        iconSize: 1.0,
        iconAnchor: IconAnchor.CENTER,
      );
    }).toList();

    await _annotationManager!.createMulti(options);
  }

  Future<void> _displayClusters(List<Moment> moments, bool isDark) async {
    // Algoritmo di clustering semplice basato su griglia
    final clusters = _createClusters(moments);

    // Registra icona cluster
    const clusterIconId = 'cluster-icon';

    for (final cluster in clusters) {
      if (cluster.moments.length == 1) {
        // Singolo momento: usa icona normale
        await _displayIndividualMarkers([cluster.moments.first], isDark);
      } else {
        // Cluster: crea icona con contatore
        final clusterBytes = await MomentMarkerIcon.createClusterMarker(
          count: cluster.moments.length,
          isDark: isDark,
        );

        final clusterIconIdWithCount =
            '$clusterIconId-${cluster.moments.length}';
        final mbxImage = MbxImage(width: 64, height: 64, data: clusterBytes);

        try {
          await _mapboxMap!.style.addStyleImage(
            clusterIconIdWithCount,
            1.0,
            mbxImage,
            false,
            [],
            [],
            null,
          );
        } catch (e) {
          // Icona già esistente
        }

        final option = PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(cluster.centerLon, cluster.centerLat),
          ),
          iconImage: clusterIconIdWithCount,
          iconSize: 1.0,
          iconAnchor: IconAnchor.CENTER,
        );

        await _annotationManager!.create(option);
      }
    }
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
