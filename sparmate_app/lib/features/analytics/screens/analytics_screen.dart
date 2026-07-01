import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/elo_forecast_card.dart';
import '../widgets/rating_overview_card.dart';
import '../widgets/phase_accuracy_card.dart';
import '../widgets/match_results_card.dart';
import '../widgets/insights_card.dart';
import '../widgets/top_opponents_card.dart';

/// Analytics screen — wired to live API data via Provider.
/// Fetches analytics overview on init and supports pull-to-refresh.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isAuthenticated) {
        state.fetchAnalytics();
      }
    });
  }

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    if (state.isAuthenticated) await state.fetchAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();
    final analytics = state.analyticsData;
    final isLoading = state.analyticsLoading;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                      // Refresh button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isLoading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : IconButton(
                                key: const ValueKey('refresh'),
                                icon: const Icon(Icons.refresh_rounded),
                                color: AppColors.primaryBlue,
                                iconSize: 22,
                                tooltip: 'Refresh analytics',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _refresh,
                              ),
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
                      Text(
                        'Analytics',
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (analytics != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Cards ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    RatingOverviewCard(
                      ratingData: analytics?['rating'] as Map<String, dynamic>?,
                    ),
                    const SizedBox(height: 16),
                    EloForecastCard(
                      forecastData: analytics?['elo_forecast'] as Map<String, dynamic>?,
                      currentElo: (analytics?['rating']?['current'] as num?)?.toInt()
                          ?? (state.user?['elo_rating'] as num?)?.toInt()
                          ?? 1200,
                    ),
                    const SizedBox(height: 16),
                    PhaseAccuracyCard(
                      phaseData: analytics?['phase_accuracy'] as Map<String, dynamic>?,
                    ),
                    const SizedBox(height: 16),
                    MatchResultsCard(
                      matchData: analytics?['matches'] as Map<String, dynamic>?,
                    ),
                    const SizedBox(height: 16),
                    InsightsCard(
                      insights: analytics?['insights'] as List<dynamic>?,
                    ),
                    const SizedBox(height: 16),
                    TopOpponentsCard(
                      opponents: analytics?['top_opponents'] as List<dynamic>?,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
