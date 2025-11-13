import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/profile_repository.dart';
import '../models/profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _repository = ProfileRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _profile;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await _repository.getOrCreateProfile(user.id);
      _profile = profile;
      _displayNameController.text = profile.displayName ?? '';
      _usernameController.text = profile.username ?? '';
      _bioController.text = profile.bio ?? '';
    } catch (error) {
      _showSnack('Impossibile caricare il profilo: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _profile == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = await _repository.updateProfile(
        _profile!.copyWith(
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
          username: _usernameController.text.trim().isEmpty
              ? null
              : _usernameController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
        ),
      );

      setState(() => _profile = updated);
      _showSnack('Profilo aggiornato.');
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        _showSnack('Questo username è già in uso.');
      } else {
        _showSnack(error.message);
      }
    } catch (error) {
      _showSnack('Errore: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Sessione non attiva. Effettua nuovamente l\'accesso.'),
      );
    }

    final theme = Theme.of(context);
    final initials = (user.email ?? 'PF').substring(0, 1).toUpperCase();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          Text(
            'Cura la tua presenza',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiorna i dettagli visibili nella community e racconta chi sei.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.black54,
            ),
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          initials,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayNameController.text.isEmpty
                                  ? 'Crea un alias'
                                  : _displayNameController.text,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '@${_usernameController.text.isEmpty ? 'username' : _usernameController.text}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ProfileField(
                    controller: _displayNameController,
                    label: 'Nome visibile',
                    hint: 'Es. Martina G.',
                    validator: (value) {
                      if ((value ?? '').trim().length > 60) {
                        return 'Max 60 caratteri';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'esploratore42',
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (username.isEmpty) {
                        return 'Inserisci uno username.';
                      }
                      final regex = RegExp(r'^[a-z0-9_.]{3,20}$');
                      if (!regex.hasMatch(username)) {
                        return '3-20 caratteri, solo lettere, numeri, . e _';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: _bioController,
                    label: 'Bio',
                    hint: 'Racconta la tua storia in 160 caratteri',
                    maxLines: 4,
                    validator: (value) {
                      if ((value ?? '').length > 160) {
                        return 'Max 160 caratteri';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Salva profilo'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dettagli account',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _AccountTile(
                  icon: Icons.alternate_email_outlined,
                  title: 'Email',
                  subtitle: user.email ?? 'Non disponibile',
                ),
                if (_profile?.role != null) ...[
                  const SizedBox(height: 12),
                  _AccountTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Ruolo',
                    subtitle: _profile!.role!,
                  ),
                ],
                const SizedBox(height: 12),
                _AccountTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Ultimo aggiornamento',
                  subtitle: _profile?.updatedAt?.toLocal().toString() ?? 'Non disponibile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
