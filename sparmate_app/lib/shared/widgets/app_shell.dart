import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/history/screens/match_history_screen.dart';
import '../../features/lessons/screens/lessons_screen.dart';
import '../../features/sparring/screens/gm_selection_screen.dart';
import 'bottom_nav_bar.dart';

/// Root shell that manages bottom navigation and switches between
/// Home, Play, Lessons, and Analytics screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    GmSelectionScreen(),
    LessonsScreen(),
    MatchHistoryScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SparMateBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// Placeholder for screens not yet implemented.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryBlue.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coming soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
