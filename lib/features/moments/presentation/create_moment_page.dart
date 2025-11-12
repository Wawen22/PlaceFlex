import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profile = _profile;
    if (profile == null) {
      _showSnack('Profilo non disponibile.');
      return;
    }

    if (_mediaType != MomentMediaType.text && _selectedFile == null) {
      _showSnack('Seleziona un file media per questo tipo di contenuto.');
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (latitude == null || longitude == null) {
      _showSnack('Inserisci coordinate valide.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

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
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuovo momento')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo momento')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titolo', hintText: 'Es. Tramonto al Duomo'),
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
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    hintText: 'Aggiungi una breve descrizione',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Text('Tipo contenuto', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<MomentMediaType>(
                  segments: [
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
                    label: Text(_selectedFile == null ? 'Seleziona immagine' : 'Cambia immagine'),
                  ),
                  if (_previewBytes != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_previewBytes!, height: 180, fit: BoxFit.cover),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Text('Visibilità', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<MomentVisibility>(
                  segments: [
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(labelText: 'Latitudine'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Latitudine richiesta';
                          }
                          return double.tryParse(value.trim()) == null ? 'Valore non valido' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(labelText: 'Longitudine'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Longitudine richiesta';
                          }
                          return double.tryParse(value.trim()) == null ? 'Valore non valido' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _detectPosition,
                  icon: const Icon(Icons.my_location_outlined),
                  label: const Text('Usa posizione attuale'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
