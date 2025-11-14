import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/colors_2026.dart';
import '../../../core/theme/spacing_2026.dart';
import '../../../core/widgets/modern_button.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/modern_text_field.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/models/profile.dart';
import '../data/moment_media_processor.dart';
import '../data/moments_repository.dart';
import '../data/prepared_moment_media.dart';
import '../models/moment.dart';

/// Redesigned CreateMomentPage 2026 - Step-by-step wizard
class CreateMomentPage2026 extends StatefulWidget {
  const CreateMomentPage2026({
    super.key,
    this.onMomentCreated,
    this.initialPosition,
  });

  final VoidCallback? onMomentCreated;
  final Position? initialPosition;

  @override
  State<CreateMomentPage2026> createState() => _CreateMomentPage2026State();
}

class _CreateMomentPage2026State extends State<CreateMomentPage2026> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _profileRepository = ProfileRepository();
  final _momentsRepository = MomentsRepository();
  final _mediaProcessor = MomentMediaProcessor();
  final _imagePicker = ImagePicker();
  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();

  UserProfile? _profile;
  bool _isLoadingProfile = true;
  bool _isSubmitting = false;
  int _currentStep = 0;
  MomentMediaType _mediaType = MomentMediaType.photo;
  MomentVisibility _visibility = MomentVisibility.public;
  XFile? _selectedFile;
  Uint8List? _previewBytes;
  PreparedMomentMedia? _preparedMedia;
  bool _isProcessingMedia = false;
  bool _isRecordingAudio = false;
  bool _isPlayingAudio = false;
  Timer? _audioTimer;
  Duration _currentRecordingDuration = Duration.zero;
  String? _audioPath;
  StreamSubscription<void>? _audioCompleteSub;
  double _uploadProgress = 0;
  MediaUploadPhase _uploadPhase = MediaUploadPhase.idle;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _audioCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlayingAudio = false);
    });

    // Pre-fill lat/lon if initial position provided
    if (widget.initialPosition != null) {
      _latitudeController.text = widget.initialPosition!.latitude
          .toStringAsFixed(6);
      _longitudeController.text = widget.initialPosition!.longitude
          .toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
     _audioTimer?.cancel();
     _audioCompleteSub?.cancel();
     unawaited(_audioRecorder.dispose());
     _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw StateError('Sessione non trovata.');
      }

      final profile = await _profileRepository.getOrCreateProfile(user.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
      _showSnack('Errore caricamento profilo: $error', isSuccess: false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      await _prepareSelectedMedia(file, cachedBytes: bytes);
    } catch (error) {
      _showSnack('Errore selezione immagine: $error', isSuccess: false);
    }
  }

  Future<void> _startAudioRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showSnack('Concedi l\'accesso al microfono', isSuccess: false);
      return;
    }

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
      ),
    );

    _audioTimer?.cancel();
    _audioTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentRecordingDuration += const Duration(seconds: 1);
      });
    });

    setState(() {
      _isRecordingAudio = true;
      _currentRecordingDuration = Duration.zero;
      _preparedMedia = null;
      _selectedFile = null;
      _previewBytes = null;
      _audioPath = null;
    });
  }

  Future<void> _stopAudioRecording() async {
    final path = await _audioRecorder.stop();
    _audioTimer?.cancel();
    if (path == null) {
      setState(() => _isRecordingAudio = false);
      return;
    }

    setState(() => _isRecordingAudio = false);
    final file = XFile(path, mimeType: 'audio/mp4');
    await _prepareSelectedMedia(
      file,
      overrideDuration: _currentRecordingDuration,
    );
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioPath == null) return;
    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }

    setState(() => _isPlayingAudio = true);
    await _audioPlayer.play(DeviceFileSource(_audioPath!));
  }

  void _resetMediaSelection() {
    _audioTimer?.cancel();
    unawaited(_audioPlayer.stop());
    setState(() {
      _selectedFile = null;
      _preparedMedia = null;
      _previewBytes = null;
      _audioPath = null;
      _isPlayingAudio = false;
      _isRecordingAudio = false;
      _currentRecordingDuration = Duration.zero;
    });
  }

  Future<void> _pickVideo() async {
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (file == null) return;
      await _prepareSelectedMedia(file);
    } catch (error) {
      _showSnack('Errore selezione video: $error', isSuccess: false);
    }
  }

  Future<void> _prepareSelectedMedia(
    XFile file, {
    Uint8List? cachedBytes,
    Duration? overrideDuration,
  }) async {
    setState(() => _isProcessingMedia = true);
    try {
      final processed = await _mediaProcessor.process(
        mediaType: _mediaType,
        file: file,
        cachedBytes: cachedBytes,
        recordedDuration: overrideDuration,
      );
      if (!mounted) return;
      setState(() {
        _selectedFile = file;
        _preparedMedia = processed;
        _previewBytes = processed.previewBytes ??
            (processed.type == MomentMediaType.photo ? processed.bytes : null);
        if (_mediaType == MomentMediaType.audio) {
          _audioPath = file.path;
          _isPlayingAudio = false;
        } else {
          _audioPath = null;
          _currentRecordingDuration = Duration.zero;
          _isPlayingAudio = false;
        }
      });
    } catch (error) {
      _showSnack('Errore elaborazione media: $error', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isProcessingMedia = false);
      }
    }
  }

  Future<void> _detectPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Attiva i servizi di geolocalizzazione', isSuccess: false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showSnack('Permessi geolocalizzazione negati', isSuccess: false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });
      _showSnack('Posizione rilevata! 📍', isSuccess: true);
    } catch (error) {
      _showSnack('Errore rilevamento posizione: $error', isSuccess: false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _profile == null) {
      return;
    }

    if (_mediaType != MomentMediaType.text && _preparedMedia == null) {
      _showSnack('Seleziona o registra un media', isSuccess: false);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadPhase = MediaUploadPhase.preparing;
      _uploadProgress = 0.05;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('Sessione scaduta. Effettua nuovamente il login.');
      }

      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _momentsRepository.createMoment(
        CreateMomentInput(
          profileId: userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          mediaType: _mediaType,
          mediaFile: _selectedFile,
          preparedMedia: _preparedMedia,
          mediaSizeBytes: _preparedMedia?.sizeBytes,
          mediaDurationMs: _preparedMedia?.duration?.inMilliseconds,
          visibility: _visibility,
          latitude: latitude,
          longitude: longitude,
          tags: tags,
          processingStatus: _mediaType == MomentMediaType.video
              ? MomentMediaProcessingStatus.queued
              : MomentMediaProcessingStatus.ready,
        ),
        onProgress: _handleUploadProgress,
      );

      if (!mounted) return;
      _showSnack('Momento pubblicato! 🎉', isSuccess: true);
      widget.onMomentCreated?.call();
      Navigator.of(context).pop(true);
    } catch (error) {
      _showSnack('Errore pubblicazione: ' + error.toString(), isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadPhase = MediaUploadPhase.idle;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _handleUploadProgress(MediaUploadProgress progress) {
    if (!mounted) return;
    setState(() {
      _uploadPhase = progress.phase;
      _uploadProgress = progress.progress.clamp(0, 1);
    });
  }

  void _showSnack(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? AppColors2026.success
            : AppColors2026.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXL),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) {
      return '--';
    }

    const units = ['B', 'KB', 'MB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _mediaLimitLabel(MomentMediaType type) {
    return switch (type) {
      MomentMediaType.photo =>
        'Foto compresse automaticamente • max 6 MB',
      MomentMediaType.video =>
        'Video 2 min / 80 MB (720p) • verrà messo in coda per la transcodifica',
      MomentMediaType.audio =>
        'Audio AAC a 96 kbps • max 2 min (20 MB)',
      MomentMediaType.text => 'Nessun file richiesto',
    };
  }

  String _uploadPhaseLabel() {
    return switch (_uploadPhase) {
      MediaUploadPhase.preparing => 'Preparo il media…',
      MediaUploadPhase.uploading => 'Invio al cloud…',
      MediaUploadPhase.saving => 'Registro il momento…',
      MediaUploadPhase.completed => 'Pronto!',
      MediaUploadPhase.idle => '',
    };
  }

  Widget _buildMediaMetaInfo(ThemeData theme) {
    final media = _preparedMedia;
    if (media == null) return const SizedBox.shrink();
    final durationLabel = media.duration != null
        ? _formatDuration(media.duration)
        : null;

    return Container(
      padding: AppSpacing2026.allMD,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: AppRadius2026.roundedXL,
      ),
      child: Row(
        children: [
          Icon(Icons.sd_storage_rounded,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing2026.sm),
          Text(
            _formatFileSize(media.sizeBytes),
            style: theme.textTheme.bodyMedium,
          ),
          if (durationLabel != null) ...[
            const SizedBox(width: AppSpacing2026.lg),
            Icon(Icons.timer_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing2026.xs),
            Text(
              durationLabel,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioRecorderSection(ThemeData theme) {
    final effectiveDuration = _preparedMedia?.duration ??
        (_currentRecordingDuration > Duration.zero
            ? _currentRecordingDuration
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nota vocale',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatDuration(effectiveDuration),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing2026.sm),
        ModernButton(
          onPressed:
              _isRecordingAudio ? _stopAudioRecording : _startAudioRecording,
          variant: ModernButtonVariant.primary,
          size: ModernButtonSize.large,
          isExpanded: true,
          icon: _isRecordingAudio
              ? Icons.stop_circle_rounded
              : Icons.mic_rounded,
          child: Text(
            _isRecordingAudio ? 'Ferma registrazione' : 'Registra audio',
          ),
        ),
        if (_audioPath != null && !_isRecordingAudio) ...[
          const SizedBox(height: AppSpacing2026.sm),
          ModernButton(
            onPressed: _toggleAudioPlayback,
            variant: ModernButtonVariant.outlined,
            size: ModernButtonSize.medium,
            isExpanded: true,
            icon: _isPlayingAudio
                ? Icons.pause_circle_rounded
                : Icons.play_circle_rounded,
            child: Text(
              _isPlayingAudio ? 'Metti in pausa' : 'Ascolta anteprima',
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingProfile) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppGradients2026.backgroundDark
                : AppGradients2026.backgroundLight,
          ),
          child: Center(
            child: CircularProgressIndicator(color: AppColors2026.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors2026.backgroundDark
          : AppColors2026.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Nuovo momento'),
        actions: [
          Padding(
            padding: AppSpacing2026.horizontalSM,
            child: Center(
              child: Text(
                'Step ${_currentStep + 1}/3',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors2026.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Details(theme),
                  _buildStep2Media(theme),
                  _buildStep3Location(theme),
                ],
              ),
            ),
          ),

          // Bottom actions
          _buildBottomActions(theme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: AppSpacing2026.allSM,
      child: Row(
        children: List.generate(
          3,
          (index) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: AppSpacing2026.xxxs),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors2026.primary
                    : AppColors2026.border,
                borderRadius: AppRadius2026.roundedFull,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Details(ThemeData theme) {
    return ListView(
      padding: AppSpacing2026.allLG,
      children: [
        Icon(
          Icons.edit_note_rounded,
          size: AppIconSize2026.huge,
          color: AppColors2026.primary,
        ),
        const SizedBox(height: AppSpacing2026.md),
        Text(
          'Raccontaci il tuo momento',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing2026.xs),
        Text(
          'Aggiungi un titolo e una descrizione coinvolgente',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing2026.xl),
        ModernCard(
          variant: ModernCardVariant.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModernTextField(
                controller: _titleController,
                label: 'Titolo',
                hint: 'Es. Tramonto mozzafiato al Duomo',
                prefixIcon: Icons.title_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing2026.md),
              ModernTextField(
                controller: _descriptionController,
                label: 'Descrizione (opzionale)',
                hint: 'Aggiungi contesto, emozioni, curiosità...',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing2026.md),
              ModernTextField(
                controller: _tagsController,
                label: 'Tag (opzionali)',
                hint: 'Es. street-art, tramonto',
                prefixIcon: Icons.tag_rounded,
                helperText: 'Separa i tag con una virgola',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Media(ThemeData theme) {
    return ListView(
      padding: AppSpacing2026.allLG,
      children: [
        Icon(
          Icons.color_lens_rounded,
          size: AppIconSize2026.huge,
          color: AppColors2026.accent,
        ),
        const SizedBox(height: AppSpacing2026.md),
        Text(
          'Scegli il tipo di contenuto',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing2026.xs),
        Text(
          _mediaLimitLabel(_mediaType),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing2026.xl),
        ModernCard(
          variant: ModernCardVariant.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tipo contenuto',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing2026.sm),
              SegmentedButton<MomentMediaType>(
                segments: const [
                  ButtonSegment(
                    value: MomentMediaType.photo,
                    icon: Icon(Icons.photo_camera_rounded),
                    label: Text('Foto'),
                  ),
                  ButtonSegment(
                    value: MomentMediaType.video,
                    icon: Icon(Icons.movie_creation_rounded),
                    label: Text('Video'),
                  ),
                  ButtonSegment(
                    value: MomentMediaType.audio,
                    icon: Icon(Icons.mic_rounded),
                    label: Text('Audio'),
                  ),
                  ButtonSegment(
                    value: MomentMediaType.text,
                    icon: Icon(Icons.text_fields_rounded),
                    label: Text('Testo'),
                  ),
                ],
                selected: <MomentMediaType>{_mediaType},
                onSelectionChanged: (values) {
                  if (values.isEmpty) return;
                  final nextType = values.first;
                  if (nextType == _mediaType) return;
                  setState(() {
                    _mediaType = nextType;
                    _resetMediaSelection();
                  });
                },
              ),
              if (_isProcessingMedia) ...[
                const SizedBox(height: AppSpacing2026.md),
                Row(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2.5),
                    const SizedBox(width: AppSpacing2026.sm),
                    Expanded(
                      child: Text(
                        'Ottimizzo il file per la pubblicazione...',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              if (_mediaType == MomentMediaType.photo) ...[
                const SizedBox(height: AppSpacing2026.lg),
                if (_previewBytes != null) ...[
                  ClipRRect(
                    borderRadius: AppRadius2026.roundedXL,
                    child: Image.memory(
                      _previewBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSpacing2026.sm),
                ],
                ModernButton(
                  onPressed: _isProcessingMedia ? null : _pickImage,
                  variant: ModernButtonVariant.outlined,
                  size: ModernButtonSize.large,
                  isExpanded: true,
                  icon: _selectedFile == null
                      ? Icons.add_photo_alternate_rounded
                      : Icons.change_circle_rounded,
                  child: Text(
                    _selectedFile == null ? 'Seleziona foto' : 'Cambia foto',
                  ),
                ),
              ] else if (_mediaType == MomentMediaType.video) ...[
                const SizedBox(height: AppSpacing2026.lg),
                if (_previewBytes != null) ...[
                  ClipRRect(
                    borderRadius: AppRadius2026.roundedXL,
                    child: Image.memory(
                      _previewBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSpacing2026.sm),
                ],
                ModernButton(
                  onPressed: _isProcessingMedia ? null : _pickVideo,
                  variant: ModernButtonVariant.outlined,
                  size: ModernButtonSize.large,
                  isExpanded: true,
                  icon: _selectedFile == null
                      ? Icons.movie_creation_rounded
                      : Icons.change_circle_rounded,
                  child: Text(
                    _selectedFile == null ? 'Seleziona video' : 'Cambia video',
                  ),
                ),
              ] else if (_mediaType == MomentMediaType.audio) ...[
                const SizedBox(height: AppSpacing2026.lg),
                _buildAudioRecorderSection(theme),
              ],
              if (_preparedMedia != null &&
                  _mediaType != MomentMediaType.text) ...[
                const SizedBox(height: AppSpacing2026.md),
                _buildMediaMetaInfo(theme),
              ],
              const SizedBox(height: AppSpacing2026.lg),
              Divider(color: theme.colorScheme.outline),
              const SizedBox(height: AppSpacing2026.sm),
              Text(
                'Visibilità',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing2026.sm),
              SegmentedButton<MomentVisibility>(
                segments: const [
                  ButtonSegment(
                    value: MomentVisibility.public,
                    icon: Icon(Icons.public_rounded),
                    label: Text('Pubblico'),
                  ),
                  ButtonSegment(
                    value: MomentVisibility.private,
                    icon: Icon(Icons.lock_rounded),
                    label: Text('Privato'),
                  ),
                ],
                selected: <MomentVisibility>{_visibility},
                onSelectionChanged: (values) {
                  if (values.isEmpty) return;
                  setState(() => _visibility = values.first);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Location(ThemeData theme) {
    return ListView(
      padding: AppSpacing2026.allLG,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: AppIconSize2026.huge,
          color: AppColors2026.accent,
        ),
        const SizedBox(height: AppSpacing2026.md),
        Text(
          'Dove ti trovi?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing2026.xs),
        Text(
          'Aggiungi la posizione per geolocalizzare il momento',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing2026.xl),
        ModernCard(
          variant: ModernCardVariant.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModernButton(
                onPressed: _detectPosition,
                variant: ModernButtonVariant.primary,
                size: ModernButtonSize.large,
                isExpanded: true,
                icon: Icons.my_location_rounded,
                elevation: 2,
                child: const Text('Usa posizione attuale'),
              ),
              const SizedBox(height: AppSpacing2026.lg),
              Text(
                'Oppure inserisci manualmente',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing2026.md),
              Row(
                children: [
                  Expanded(
                    child: ModernTextField(
                      controller: _latitudeController,
                      label: 'Latitudine',
                      hint: '45.464664',
                      prefixIcon: Icons.straighten_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Richiesto';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Non valido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing2026.sm),
                  Expanded(
                    child: ModernTextField(
                      controller: _longitudeController,
                      label: 'Longitudine',
                      hint: '9.188540',
                      prefixIcon: Icons.straighten_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Richiesto';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Non valido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors2026.surfaceDark : AppColors2026.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors2026.borderDark : AppColors2026.border,
          ),
        ),
      ),
      padding: AppSpacing2026.allLG,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isSubmitting) ...[
              LinearProgressIndicator(
                value: _uploadProgress.clamp(0, 1),
              ),
              const SizedBox(height: AppSpacing2026.sm),
              Text(
                _uploadPhaseLabel(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing2026.md),
            ],
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: ModernButton(
                      onPressed: _previousStep,
                      variant: ModernButtonVariant.outlined,
                      size: ModernButtonSize.large,
                      icon: Icons.arrow_back_rounded,
                      child: const Text('Indietro'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: AppSpacing2026.sm),
                Expanded(
                  child: ModernButton(
                    onPressed: _currentStep < 2
                        ? _nextStep
                        : (_isSubmitting ? null : _submit),
                    variant: ModernButtonVariant.primary,
                    size: ModernButtonSize.large,
                    isExpanded: true,
                    isLoading: _isSubmitting,
                    icon: _currentStep < 2
                        ? Icons.arrow_forward_rounded
                        : Icons.rocket_launch_rounded,
                    elevation: 4,
                    child: Text(_currentStep < 2 ? 'Avanti' : 'Pubblica'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
