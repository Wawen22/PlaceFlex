import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/glass_card.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/models/profile.dart';
import '../data/moments_repository.dart';
import '../models/moment.dart';

class CreateMomentPage extends StatefulWidget {
  const CreateMomentPage({super.key, this.onMomentCreated});

  final VoidCallback? onMomentCreated;

  @override
  State<CreateMomentPage> createState() => _CreateMomentPageState();
}

class _CreateMomentPageState extends State<CreateMomentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _profileRepository = ProfileRepository();
  final _momentsRepository = MomentsRepository();
  final _imagePicker = ImagePicker();

  UserProfile? _profile;
  bool _isLoadingProfile = true;
  bool _isSubmitting = false;
  MomentMediaType _mediaType = MomentMediaType.photo;
  MomentVisibility _visibility = MomentVisibility.public;
  XFile? _selectedFile;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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
      setState(() {
        _isLoadingProfile = false;
      });
      _showSnack('Impossibile caricare il profilo: $error');
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedFile = file;
        _previewBytes = bytes;
      });
    } catch (error) {
      _showSnack('Errore durante la selezione dell\'immagine: $error');
    }
  }

  Future<void> _detectPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Servizi di geolocalizzazione disattivati. Attivali e riprova.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        _showSnack('Permessi geolocalizzazione negati. Inserisci manualmente le coordinate.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });
    } catch (error) {
      _showSnack('Impossibile recuperare la posizione: $error');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _profile == null) {
      return;
    }

    if (_mediaType != MomentMediaType.text && _selectedFile == null) {
      _showSnack('Seleziona un media per continuare.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      final profile = _profile!;

      await _momentsRepository.createMoment(
        CreateMomentInput(
          profileId: profile.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          mediaType: _mediaType,
          mediaFile: _selectedFile,
          visibility: _visibility,
          latitude: latitude,
          longitude: longitude,
          tags: tags,
        ),
      );

      if (!mounted) return;
      _showSnack('Momento pubblicato!');
      widget.onMomentCreated?.call();
      Navigator.of(context).pop();
    } catch (error) {
      _showSnack('Errore durante la creazione del momento: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingProfile) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.mainBackground),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF7F5FF),
              Color(0xFFE7EDFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nuovo momento',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Racconta cosa sta succedendo dove sei.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Theme(
                    data: theme.copyWith(
                      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                        fillColor: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Dettagli principali',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Titolo',
                            hintText: 'Es. Tramonto al Duomo',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci un titolo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Descrizione',
                            hintText: 'Aggiungi contesto, emozioni, curiosità',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Media e visibilità',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tipo contenuto',
                        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<MomentMediaType>(
                        segments: const [
                          ButtonSegment(
                            value: MomentMediaType.photo,
                            icon: Icon(Icons.photo_camera_back_outlined),
                            label: Text('Foto'),
                          ),
                          ButtonSegment(
                            value: MomentMediaType.text,
                            icon: Icon(Icons.text_fields_outlined),
                            label: Text('Testo'),
                          ),
                        ],
                        selected: <MomentMediaType>{_mediaType},
                        onSelectionChanged: (values) {
                          if (values.isEmpty) return;
                          final value = values.first;
                          setState(() {
                            _mediaType = value;
                            if (value == MomentMediaType.text) {
                              _selectedFile = null;
                              _previewBytes = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_mediaType == MomentMediaType.photo) ...[
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _selectedFile == null ? 'Seleziona immagine' : 'Cambia immagine',
                          ),
                        ),
                        if (_previewBytes != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.memory(
                              _previewBytes!,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Visibilità',
                        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<MomentVisibility>(
                        segments: const [
                          ButtonSegment(
                            value: MomentVisibility.public,
                            icon: Icon(Icons.public_outlined),
                            label: Text('Pubblico'),
                          ),
                          ButtonSegment(
                            value: MomentVisibility.private,
                            icon: Icon(Icons.lock_outline),
                            label: Text('Privato'),
                          ),
                        ],
                        selected: <MomentVisibility>{_visibility},
                        onSelectionChanged: (values) {
                          if (values.isEmpty) return;
                          setState(() => _visibility = values.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tag (opzionali)',
                          hintText: 'es. street-art, tramonto',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Coordinate',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              decoration: const InputDecoration(labelText: 'Latitudine'),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Latitudine richiesta';
                                }
                                return double.tryParse(value.trim()) == null
                                    ? 'Valore non valido'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              decoration: const InputDecoration(labelText: 'Longitudine'),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Longitudine richiesta';
                                }
                                return double.tryParse(value.trim()) == null
                                    ? 'Valore non valido'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _detectPosition,
                        icon: const Icon(Icons.my_location_outlined),
                        label: const Text('Usa posizione attuale'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Pubblica momento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
