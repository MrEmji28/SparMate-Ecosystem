import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/grandmaster_hero_card.dart';
import '../widgets/active_lesson_card.dart';
import '../widgets/analytics_card.dart';
import '../widgets/coaching_engine_card.dart';
import '../widgets/daily_puzzles_card.dart';
import '../widgets/tactics_card.dart';

/// Home screen — the main dashboard.
/// Fetches coaching and analytics data on init via Provider.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isAuthenticated) {
        state.fetchDashboard();
        state.fetchCoachingPlan();
        state.fetchAnalytics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SparMate',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      key: const Key('profile-menu'),
                      offset: const Offset(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      color: Colors.white,
                      elevation: 8,
                      onSelected: (value) {
                        if (value == 'logout') {
                          context.read<AppState>().logout();
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.read<AppState>().user?['name'] ?? 'Player',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.read<AppState>().user?['email'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 18, color: AppColors.liveRed),
                              SizedBox(width: 10),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: AppColors.liveRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primaryBlue, AppColors.primaryLight],
                          ),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const GrandmasterHeroCard(),
                  const SizedBox(height: 16),

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        Expanded(child: ActiveLessonCard()),
                        SizedBox(width: 12),
                        Expanded(child: AnalyticsCard()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const CoachingEngineCard(),
                  const SizedBox(height: 16),

                  const DailyPuzzlesCard(),
                  const SizedBox(height: 16),

                  const TacticsCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
