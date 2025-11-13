import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/colors_2026.dart';
import '../../../core/theme/spacing_2026.dart';
import '../../map/presentation/map_screen.dart';
import '../../moments/presentation/create_moment_page_2026.dart';
import '../../profile/presentation/profile_page_2026.dart';

/// Redesigned HomeShell 2026 - Navigation moderna con blur effects
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma uscita'),
        content: const Text('Sei sicuro di voler uscire?'),
        shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXL),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  Future<void> _openCreateMoment() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return CreateMomentPage2026(
            onMomentCreated: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Momento creato con successo! 🎉'),
                  backgroundColor: AppColors2026.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius2026.roundedXL,
                  ),
                ),
              );
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = <Widget>[
      const MapScreen(), // Mappa come prima tab
      const ProfilePage2026(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark
          ? AppColors2026.backgroundDark
          : AppColors2026.backgroundLight,

      // Modern AppBar with blur
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor:
                  (isDark
                          ? AppColors2026.surfaceDark
                          : AppColors2026.surfaceLight)
                      .withOpacity(0.8),
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: AppSpacing2026.allXXS,
                    decoration: BoxDecoration(
                      gradient: AppGradients2026.buttonPrimary,
                      borderRadius: AppRadius2026.roundedMD,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: AppIconSize2026.md,
                    ),
                  ),
                  const SizedBox(width: AppSpacing2026.xs),
                  Text(
                    _selectedIndex == 0 ? 'Scopri' : 'Profilo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              actions: [
                if (_selectedIndex == 0)
                  IconButton(
                    tooltip: 'Notifiche',
                    onPressed: () {
                      // TODO: Implement notifications
                    },
                    icon: Badge(
                      label: const Text('3'),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Esci',
                  onPressed: _signOut,
                  icon: Icon(
                    Icons.logout_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing2026.xxs),
              ],
            ),
          ),
        ),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          child: pages[_selectedIndex],
        ),
      ),

      // Modern FAB with scale animation
      floatingActionButton: _selectedIndex == 0
          ? ScaleTransition(
              scale: CurvedAnimation(
                parent: _fabController,
                curve: Curves.easeInOut,
              ),
              child: FloatingActionButton.extended(
                onPressed: _openCreateMoment,
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('Nuovo momento'),
                elevation: 4,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Modern Bottom Nav
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? AppColors2026.surfaceDark
                          : AppColors2026.surfaceLight)
                      .withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors2026.borderDark
                      : AppColors2026.border,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing2026.xxs,
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: 'Scopri',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profilo',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
