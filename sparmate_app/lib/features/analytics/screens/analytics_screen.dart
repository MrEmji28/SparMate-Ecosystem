import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/rating_overview_card.dart';
import '../widgets/phase_accuracy_card.dart';
import '../widgets/match_results_card.dart';
import '../widgets/insights_card.dart';
import '../widgets/top_opponents_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
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
                child: Text(
                  'Analytics',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),

            // ── Cards ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const RatingOverviewCard(),
                  const SizedBox(height: 16),
                  const PhaseAccuracyCard(),
                  const SizedBox(height: 16),
                  const MatchResultsCard(),
                  const SizedBox(height: 16),
                  const InsightsCard(),
                  const SizedBox(height: 16),
                  const TopOpponentsCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
