import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/auth_page.dart';
import '../features/home/presentation/home_shell.dart';
import 'theme.dart';

class PlaceFlexApp extends StatefulWidget {
  const PlaceFlexApp({super.key});

  @override
  State<PlaceFlexApp> createState() => _PlaceFlexAppState();
}

class _PlaceFlexAppState extends State<PlaceFlexApp> {
  Session? _session;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _session = auth.currentSession;
    _authSubscription = auth.onAuthStateChange.listen(_handleAuthStateChange);
  }

  void _handleAuthStateChange(AuthState data) {
    setState(() {
      _session = data.session;
    });

    switch (data.event) {
      case AuthChangeEvent.passwordRecovery:
        _showSnack('Recupero password avviato. Controlla la mail.');
        break;
      case AuthChangeEvent.signedIn:
        _showSnack('Accesso completato, benvenuto su PlaceFlex!');
        break;
      case AuthChangeEvent.signedOut:
        _showSnack('Sessione terminata.');
        break;
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.tokenRefreshed:
      default:
        break;
    }
  }

  void _showSnack(String message) {
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _session != null;

    return MaterialApp(
      title: 'PlaceFlex',
      theme: AppTheme.light,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      home: isAuthenticated ? const HomeShell() : const AuthPage(),
    );
  }
}
