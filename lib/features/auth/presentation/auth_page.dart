import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

import '../../../core/constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/glass_card.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        await _authRepository.signInWithEmail(email: email, password: password);
        _showSnack('Accesso completato, benvenuto su PlaceFlex!');
      } else {
        final response = await _authRepository.signUpWithEmail(
          email: email,
          password: password,
          emailRedirectTo: AppConstants.authRedirectUri,
        );
        final needsConfirmation =
            response.user == null || response.user?.emailConfirmedAt == null;
        _showSnack(
          needsConfirmation
              ? 'Registrazione completata. Controlla la mail per confermare il tuo account.'
              : 'Account creato! Benvenuto su PlaceFlex.',
        );
      }
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Errore inatteso: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
      return 'Inserisci la tua email.';
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
      return 'Inserisci la password.';
    }
    if (pwd.length < 8) {
      return 'La password deve avere almeno 8 caratteri.';
    }
    return null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(String message) {
    _showSnack(message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.mainBackground),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment:
                      isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: isWide ? 3 : 0,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: isWide ? 32 : 0,
                          bottom: isWide ? 0 : 32,
                        ),
                        child: Column(
                          crossAxisAlignment: isWide
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Trasforma i luoghi\nin ricordi condivisi',
                              textAlign: isWide ? TextAlign.left : TextAlign.center,
                              style: textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Crea momenti geolocalizzati, scopri storie attorno a te e vivi la città con occhi nuovi.',
                              textAlign: isWide ? TextAlign.left : TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
                              children: const [
                                _FeatureChip(icon: Icons.map_rounded, label: 'Mappa immersiva'),
                                _FeatureChip(icon: Icons.explore_rounded, label: 'Discovery locale'),
                                _FeatureChip(icon: Icons.bolt, label: 'Momenti interattivi'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: GlassCard(
                        child: Theme(
                          data: theme.copyWith(
                            textTheme: textTheme.apply(
                              bodyColor: Colors.white,
                              displayColor: Colors.white,
                            ),
                            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                              fillColor: Colors.white.withOpacity(0.12),
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintStyle: const TextStyle(color: Colors.white60),
                              prefixIconColor: Colors.white54,
                              suffixIconColor: Colors.white54,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isLoginMode ? 'Bentornato' : 'Crea il tuo account',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isLoginMode
                                    ? 'Inserisci le credenziali per continuare.'
                                    : 'In meno di un minuto sei pronto a pubblicare momenti.',
                                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 24),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'tu@email.com',
                                      ),
                                      validator: _validateEmail,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        hintText: 'Almeno 8 caratteri',
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                        ),
                                      ),
                                      validator: _validatePassword,
                                    ),
                                    if (!_isLoginMode) ...[
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: !_isConfirmPasswordVisible,
                                        decoration: InputDecoration(
                                          labelText: 'Conferma password',
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _isConfirmPasswordVisible =
                                                    !_isConfirmPasswordVisible;
                                              });
                                            },
                                            icon: Icon(
                                              _isConfirmPasswordVisible
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (_isLoginMode) {
                                            return null;
                                          }
                                          if ((value ?? '').isEmpty) {
                                            return 'Conferma la password.';
                                          }
                                          if (value != _passwordController.text) {
                                            return 'Le password non coincidono.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    FilledButton(
                                      onPressed: _isSubmitting ? null : _submitCredentials,
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Text(_isLoginMode ? 'Accedi' : 'Crea account'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _isSubmitting ? null : _toggleMode,
                                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                                      child: Text(
                                        _isLoginMode
                                            ? 'Nuovo su PlaceFlex? Registrati'
                                            : 'Hai già un account? Accedi',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white12, height: 32),
                              Text(
                                'Accedendo accetti i Termini di servizio e la Privacy Policy.',
                                style: textTheme.bodySmall?.copyWith(color: Colors.white60),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.25))),
      backgroundColor: Colors.white.withOpacity(0.08),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
