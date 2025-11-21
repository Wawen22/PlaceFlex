import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/colors_2026.dart';
import '../../../core/theme/spacing_2026.dart';
import '../../../core/widgets/modern_badge_avatar.dart';
import '../../../core/widgets/modern_button.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/modern_text_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../moments/data/moments_repository.dart';
import '../../moments/models/moment.dart';
import '../data/profile_repository.dart';
import '../models/profile.dart';

/// Redesigned ProfilePage 2026 - Magazine style layout
class ProfilePage2026 extends StatefulWidget {
  const ProfilePage2026({super.key});

  @override
  State<ProfilePage2026> createState() => _ProfilePage2026State();
}

class _ProfilePage2026State extends State<ProfilePage2026>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _authRepository = AuthRepository();
  final _momentsRepository = MomentsRepository();
  final _repository = ProfileRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  UserProfile? _profile;
  List<Moment>? _myMoments;


  late TabController _tabController;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      final moments = await _momentsRepository.getMyMoments(user.id);
      
      _profile = profile;
      _myMoments = moments;
      
      _displayNameController.text = profile.displayName ?? '';
      _usernameController.text = profile.username ?? '';
      _bioController.text = profile.bio ?? '';
    } catch (error) {
      _showSnack('Errore caricamento profilo: $error', isSuccess: false);
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

      setState(() {
        _profile = updated;
        _isEditing = false;
      });
      _showSnack('Profilo aggiornato! ✨', isSuccess: true);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        _showSnack('Username già in uso', isSuccess: false);
      } else {
        _showSnack(error.message, isSuccess: false);
      }
    } catch (error) {
      _showSnack('Errore: $error', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message, {required bool isSuccess}) {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors2026.primary),
      );
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Sessione scaduta. Effettua nuovamente l\'accesso.'),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors2026.backgroundDark : AppColors2026.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(theme, user, isDark),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCreatedTab(),
            _buildDiscoveredTab(),
            _buildSettingsTab(theme, user),
          ],
        ),
      ),
    );
  }
  Widget _buildSliverAppBar(ThemeData theme, User user, bool isDark) {
    final name = _profile?.displayName?.isNotEmpty == true
        ? _profile!.displayName!
        : (user.email?.isNotEmpty == true ? user.email! : 'Utente');
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors2026.surfaceDark : Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: isDark ? AppColors2026.surfaceDark : Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: theme.dividerColor,
            tabs: const [
              Tab(text: 'Creati'),
              Tab(text: 'Scoperti'),
              Tab(text: 'Impostazioni'),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          AppColors2026.primary.withOpacity(0.3),
                          AppColors2026.backgroundDark,
                        ]
                      : [
                          AppColors2026.primary.withOpacity(0.1),
                          Colors.white,
                        ],
                ),
              ),
            ),
            
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors2026.primary.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ModernAvatar(
                      initials: initials,
                      size: ModernAvatarSize.xlarge,
                      color: AppColors2026.primary,
                      hasBorder: true,
                      imageUrl: _profile?.avatarUrl,
                    ),
                  ),
                  const SizedBox(height: AppSpacing2026.md),
                  
                  // Name
                  Text(
                    name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Username
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '@${_profile?.username ?? 'username'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing2026.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _profile!.bio!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing2026.lg),
                  // Stats inside header
                  _buildStatsRow(theme),
                  
                  const SizedBox(height: AppSpacing2026.md),
                  ModernButton(
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                    variant: ModernButtonVariant.text,
                    size: ModernButtonSize.small,
                    icon: _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    child: Text(_isEditing ? 'Annulla' : 'Modifica profilo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(
          value: '${_myMoments?.length ?? 0}',
          label: 'Momenti',
        ),
        Container(height: 24, width: 1, color: theme.dividerColor),
        const _StatItem(
          value: '0',
          label: 'Mi piace',
        ),
        Container(height: 24, width: 1, color: theme.dividerColor),
        const _StatItem(
          value: '0',
          label: 'Scoperte',
        ),
      ],
    );
  }

  Widget _buildCreatedTab() {
    if (_myMoments == null || _myMoments!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun momento creato',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(), // Better for NestedScrollView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _myMoments!.length,
      itemBuilder: (context, index) {
        final moment = _myMoments![index];
        return _MomentGridItem(moment: moment);
      },
    );
  }

  Widget _buildDiscoveredTab() {
    return Padding(
      padding: AppSpacing2026.allLG,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_outlined,
              size: AppIconSize2026.huge,
              color: AppColors2026.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing2026.md),
            Text(
              'Nessuna scoperta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing2026.xs),
            Text(
              'I momenti che scopri appariranno qui',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(ThemeData theme, User user) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: AppSpacing2026.allLG,
        children: [
          if (_isEditing) ...[
            ModernCard(
              variant: ModernCardVariant.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Modifica profilo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing2026.md),
                  ModernTextField(
                    controller: _displayNameController,
                    label: 'Nome visibile',
                    hint: 'Es. Martina G.',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if ((value ?? '').trim().length > 60) {
                        return 'Max 60 caratteri';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing2026.md),
                  ModernTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'esploratore42',
                    prefixIcon: Icons.alternate_email,
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (username.isEmpty) {
                        return 'Inserisci uno username';
                      }
                      final regex = RegExp(r'^[a-z0-9_.]{3,20}$');
                      if (!regex.hasMatch(username)) {
                        return '3-20 caratteri, solo minuscole, numeri, . e _';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing2026.md),
                  ModernTextField(
                    controller: _bioController,
                    label: 'Bio',
                    hint: 'Racconta la tua storia in 160 caratteri',
                    prefixIcon: Icons.info_outline,
                    maxLines: 4,
                    validator: (value) {
                      if ((value ?? '').length > 160) {
                        return 'Max 160 caratteri';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing2026.lg),
                  ModernButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    variant: ModernButtonVariant.primary,
                    size: ModernButtonSize.large,
                    isExpanded: true,
                    isLoading: _isSaving,
                    icon: Icons.save_rounded,
                    elevation: 2,
                    child: const Text('Salva modifiche'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing2026.lg),
          ],
          ModernCard(
            variant: ModernCardVariant.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing2026.md),
                _InfoTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: user.email ?? 'N/A',
                ),
                const SizedBox(height: AppSpacing2026.sm),
                _InfoTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Ruolo',
                  value: _profile?.role ?? 'user',
                ),
                const SizedBox(height: AppSpacing2026.sm),
                _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Membro dal',
                  value: _formatDate(_profile?.createdAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MomentGridItem extends StatelessWidget {
  const _MomentGridItem({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        image: moment.thumbnailUrl != null
            ? DecorationImage(
                image: NetworkImage(moment.thumbnailUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (moment.thumbnailUrl == null)
            Center(
              child: Icon(
                Icons.image_not_supported_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          // Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Title
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              moment.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: AppColors2026.primary, size: AppIconSize2026.md),
        const SizedBox(width: AppSpacing2026.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


