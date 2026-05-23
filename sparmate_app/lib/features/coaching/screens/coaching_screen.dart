import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/primary_directive_card.dart';
import '../widgets/weekly_focus_card.dart';
import '../widgets/training_plan_card.dart';

/// Full Coaching Engine detail screen — navigated to from the home card.
class CoachingScreen extends StatelessWidget {
  const CoachingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
                      splashRadius: 22,
                    ),
                    Text(
                      'SparMate',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.primaryLight],
                        ),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),

            // ── Page title ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.psychology_rounded, size: 26, color: AppColors.primaryBlue),
                    const SizedBox(width: 10),
                    Text(
                      'Coaching Engine',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Cards ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const PrimaryDirectiveCard(),
                  const SizedBox(height: 16),
                  const WeeklyFocusCard(),
                  const SizedBox(height: 16),
                  const TrainingPlanCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
