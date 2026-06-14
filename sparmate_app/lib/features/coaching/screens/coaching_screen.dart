import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/primary_directive_card.dart';
import '../widgets/weekly_focus_card.dart';
import '../widgets/training_plan_card.dart';

/// Full Coaching Engine detail screen — wired to live BKT data via Provider.
class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch coaching plan data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchCoachingPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();

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
                    // Refresh button
                    IconButton(
                      onPressed: state.isLoading
                          ? null
                          : () => state.refreshCoachingPlan(),
                      icon: state.isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, color: AppColors.primaryBlue),
                      splashRadius: 22,
                      tooltip: 'Refresh Coaching Plan',
                    ),
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
                  PrimaryDirectiveCard(
                    directive: state.trainingPlan?['primary_directive'] as String?,
                  ),
                  const SizedBox(height: 16),
                  WeeklyFocusCard(
                    bktMatrix: state.bktMatrix?['skills'] as Map<String, dynamic>?,
                  ),
                  const SizedBox(height: 16),
                  TrainingPlanCard(
                    planItems: state.trainingPlan?['plan_items'] as List<dynamic>?,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
