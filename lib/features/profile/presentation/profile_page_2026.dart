import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/colors_2026.dart';
import '../../../core/theme/spacing_2026.dart';
import '../../../core/widgets/modern_badge_avatar.dart';
import '../../../core/widgets/modern_button.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/modern_text_field.dart';
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
  final _repository = ProfileRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  UserProfile? _profile;

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
      _profile = profile;
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

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppGradients2026.backgroundDark
            : AppGradients2026.backgroundLight,
      ),
      child: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(child: _buildProfileHeader(theme, user)),

          // Stats Row
          SliverToBoxAdapter(child: _buildStatsRow(theme)),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    text: 'Creati',
                    icon: Icon(Icons.add_location_alt_outlined),
                  ),
                  Tab(text: 'Scoperti', icon: Icon(Icons.explore_outlined)),
                  Tab(
                    text: 'Impostazioni',
                    icon: Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              isDark: isDark,
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreatedTab(),
                _buildDiscoveredTab(),
                _buildSettingsTab(theme, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, User user) {
    final initials = (_profile?.displayName ?? user.email ?? 'U')
        .substring(0, 1)
        .toUpperCase();

    return Padding(
      padding: AppSpacing2026.allLG,
      child: ModernCard(
        variant: ModernCardVariant.gradient,
        gradient: AppGradients2026.buttonPrimary,
        child: Column(
          children: [
            ModernAvatar(
              initials: initials,
              size: ModernAvatarSize.xlarge,
              color: AppColors2026.secondary,
              hasBorder: true,
            ),
            const SizedBox(height: AppSpacing2026.md),
            Text(
              _profile?.displayName ?? 'Utente',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing2026.xxxs),
            Text(
              '@${_profile?.username ?? 'username'}',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing2026.sm),
              Text(
                _profile!.bio!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing2026.md),
            ModernButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              variant: ModernButtonVariant.outlined,
              icon: _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              child: Text(_isEditing ? 'Annulla' : 'Modifica profilo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Padding(
      padding: AppSpacing2026.horizontalLG,
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.location_on_rounded,
              value: '0',
              label: 'Momenti',
              color: AppColors2026.primary,
            ),
          ),
          const SizedBox(width: AppSpacing2026.sm),
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_rounded,
              value: '0',
              label: 'Mi piace',
              color: AppColors2026.accent,
            ),
          ),
          const SizedBox(width: AppSpacing2026.sm),
          Expanded(
            child: _StatCard(
              icon: Icons.explore_rounded,
              value: '0',
              label: 'Scoperte',
              color: AppColors2026.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedTab() {
    return Padding(
      padding: AppSpacing2026.allLG,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: AppIconSize2026.huge,
              color: AppColors2026.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing2026.md),
            Text(
              'Nessun momento creato',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing2026.xs),
            Text(
              'I tuoi momenti appariranno qui',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      variant: ModernCardVariant.elevated,
      padding: AppSpacing2026.allMD,
      child: Column(
        children: [
          Icon(icon, color: color, size: AppIconSize2026.lg),
          const SizedBox(height: AppSpacing2026.xxs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar, {required this.isDark});

  final TabBar tabBar;
  final bool isDark;

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark
          ? AppColors2026.backgroundDark
          : AppColors2026.backgroundLight,
      padding: AppSpacing2026.horizontalLG,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
