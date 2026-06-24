import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/app_shell.dart';
import 'login_screen.dart';
import 'onboarding_survey_screen.dart';

/// Auth gate — reactive navigator that shows the correct screen based on
/// the user's authentication and onboarding state:
///
///  1. Not authenticated → [LoginScreen]
///  2. Authenticated but not onboarded → [OnboardingSurveyScreen]
///  3. Authenticated and onboarded → [AppShell]
///
/// Uses [AnimatedSwitcher] for smooth crossfade transitions between states.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Determine which screen to show
    final Widget child;
    if (!state.isAuthenticated) {
      child = const LoginScreen(key: ValueKey('login'));
    } else if (!state.onboardingCompleted) {
      child = const OnboardingSurveyScreen(key: ValueKey('onboarding'));
    } else {
      child = const AppShell(key: ValueKey('app'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}
