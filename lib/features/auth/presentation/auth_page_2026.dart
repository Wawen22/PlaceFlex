import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

import '../../../core/constants.dart';
import '../../../core/theme/colors_2026.dart';
import '../../../core/theme/spacing_2026.dart';
import '../../../core/widgets/modern_button.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/modern_text_field.dart';

/// Redesigned AuthPage 2026 - Hero section immersiva con gradients
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        await _authRepository.signInWithEmail(email: email, password: password);
        if (mounted) {
          _showSnack('Benvenuto su PlaceFlex! 🎉', isSuccess: true);
        }
      } else {
        final response = await _authRepository.signUpWithEmail(
          email: email,
          password: password,
          emailRedirectTo: AppConstants.authRedirectUri,
        );
        final needsConfirmation =
            response.user == null || response.user?.emailConfirmedAt == null;
        if (mounted) {
          _showSnack(
            needsConfirmation
                ? 'Controlla la mail per confermare il tuo account 📧'
                : 'Account creato! Benvenuto su PlaceFlex 🎉',
            isSuccess: true,
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) _showSnack(error.message, isSuccess: false);
    } catch (error) {
      if (mounted) _showSnack('Errore inatteso: $error', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _confirmPasswordController.clear();
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Inserisci la tua email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Email non valida';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final pwd = value ?? '';
    if (pwd.isEmpty) {
      return 'Inserisci la password';
    }
    if (pwd.length < 8) {
      return 'Minimo 8 caratteri';
    }
    return null;
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
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    final isTablet = size.width >= 600 && size.width < 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients2026.heroPrimary),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing2026.xxxl : AppSpacing2026.lg,
              vertical: AppSpacing2026.xl,
            ),
            child: Column(
              children: [
                if (isWide || isTablet) ...[
                  _buildHeroSection(theme, isWide),
                  SizedBox(
                    height: isWide ? AppSpacing2026.huge : AppSpacing2026.xxxl,
                  ),
                ],
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 480 : double.infinity,
                        ),
                        child: _buildAuthForm(theme),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, bool isWide) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: AppSpacing2026.allMD,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: AppRadius2026.roundedXL,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors2026.secondary,
                  size: AppIconSize2026.huge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing2026.lg),
          Text(
            'PlaceFlex',
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing2026.sm),
          Text(
            'Trasforma i luoghi in ricordi condivisi',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing2026.xl),
          Wrap(
            spacing: AppSpacing2026.sm,
            runSpacing: AppSpacing2026.sm,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureChip(icon: Icons.explore_rounded, label: 'Scopri luoghi'),
              _FeatureChip(
                icon: Icons.camera_alt_rounded,
                label: 'Crea momenti',
              ),
              _FeatureChip(icon: Icons.people_rounded, label: 'Connettiti'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm(ThemeData theme) {
    return ModernCard(
      variant: ModernCardVariant.glass,
      blurIntensity: 30,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isLoginMode ? 'Bentornato! 👋' : 'Inizia ora 🚀',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing2026.xxs),
            Text(
              _isLoginMode
                  ? 'Accedi al tuo account per continuare'
                  : 'Crea il tuo account in pochi secondi',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing2026.xl),

            // Email field
            ModernTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'tu@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing2026.md),

            // Password field
            ModernTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Almeno 8 caratteri',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_isPasswordVisible,
              textInputAction: _isLoginMode
                  ? TextInputAction.done
                  : TextInputAction.next,
              validator: _validatePassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white70,
                ),
              ),
            ),

            // Confirm password (signup only)
            if (!_isLoginMode) ...[
              const SizedBox(height: AppSpacing2026.md),
              ModernTextField(
                controller: _confirmPasswordController,
                label: 'Conferma password',
                hint: 'Ripeti la password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: !_isConfirmPasswordVisible,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (_isLoginMode) return null;
                  if ((value ?? '').isEmpty) {
                    return 'Conferma la password';
                  }
                  if (value != _passwordController.text) {
                    return 'Le password non coincidono';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                      () => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible,
                    );
                  },
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing2026.xl),

            // Submit button
            ModernButton(
              onPressed: _isSubmitting ? null : _submitCredentials,
              variant: ModernButtonVariant.primary,
              size: ModernButtonSize.large,
              isExpanded: true,
              isLoading: _isSubmitting,
              icon: _isLoginMode
                  ? Icons.login_rounded
                  : Icons.rocket_launch_rounded,
              elevation: 4,
              child: Text(_isLoginMode ? 'Accedi' : 'Crea account'),
            ),

            const SizedBox(height: AppSpacing2026.md),

            // Toggle mode
            ModernButton(
              onPressed: _isSubmitting ? null : _toggleMode,
              variant: ModernButtonVariant.text,
              isExpanded: true,
              child: Text(
                _isLoginMode
                    ? 'Nuovo su PlaceFlex? Registrati'
                    : 'Hai già un account? Accedi',
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: AppSpacing2026.lg),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppSpacing2026.sm),

            Text(
              'Accedendo accetti i Termini di servizio e la Privacy Policy',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing2026.md,
        vertical: AppSpacing2026.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: AppRadius2026.roundedFull,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize2026.sm, color: AppColors2026.secondary),
          const SizedBox(width: AppSpacing2026.xxs),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
