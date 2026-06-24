import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/primary_directive_card.dart';
import '../widgets/weekly_focus_card.dart';
import '../widgets/training_plan_card.dart';

/// Full Coaching Engine detail screen — wired to live BKT data via Provider.
/// Includes loading shimmer, error states, empty states, and pull-to-refresh.
class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Staggered entrance animation
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    // Fetch coaching plan data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      // Avoid redundant fetches if data was recently loaded (within 2 min)
      final lastFetch = state.lastCoachingFetch;
      if (lastFetch == null ||
          DateTime.now().difference(lastFetch).inSeconds > 120) {
        state.fetchCoachingPlan().then((_) {
          if (mounted) _animController.forward();
        });
      } else {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<AppState>().refreshCoachingPlan();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── App Bar ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.primaryNavy),
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
                            : const Icon(Icons.refresh_rounded,
                                color: AppColors.primaryBlue),
                        splashRadius: 22,
                        tooltip: 'Refresh Coaching Plan',
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryLight
                            ],
                          ),
                          border:
                              Border.all(color: AppColors.border, width: 2),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 18),
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
                      Icon(Icons.psychology_rounded,
                          size: 26, color: AppColors.primaryBlue),
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

              // ── Content (cards, error, or empty state) ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildContent(state, tt),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(AppState state, TextTheme tt) {
    // ── Error State ──
    if (state.coachingError != null &&
        state.bktMatrix == null &&
        state.trainingPlan == null) {
      return [_buildErrorState(state, tt)];
    }

    // ── Loading State (first load only) ──
    if (state.bktMatrix == null &&
        state.trainingPlan == null &&
        state.coachingError == null) {
      return _buildLoadingShimmers();
    }

    // ── Data loaded — build cards with animation ──
    return [
      FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(_fadeAnim),
          child: PrimaryDirectiveCard(
            directive:
                state.trainingPlan?['primary_directive'] as String?,
            recentIndicators: state.recentIndicators,
          ),
        ),
      ),
      const SizedBox(height: 16),
      FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
          )),
          child: WeeklyFocusCard(
            bktMatrix:
                state.bktMatrix?['skills'] as Map<String, dynamic>?,
          ),
        ),
      ),
      const SizedBox(height: 16),
      FadeTransition(
        opacity: CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          )),
          child: TrainingPlanCard(
            planItems: state.trainingPlan?['plan_items']
                as List<dynamic>?,
          ),
        ),
      ),
    ];
  }

  Widget _buildErrorState(AppState state, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.liveRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 32, color: AppColors.liveRed),
          ),
          const SizedBox(height: 20),
          Text(
            'Unable to Load Coaching Data',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.coachingError ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: state.isLoading
                ? null
                : () => state.fetchCoachingPlan().then((_) {
                      if (mounted) _animController.forward();
                    }),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLoadingShimmers() {
    return [
      _shimmerCard(height: 200),
      const SizedBox(height: 16),
      _shimmerCard(height: 160),
      const SizedBox(height: 16),
      _shimmerCard(height: 240),
    ];
  }

  Widget _shimmerCard({required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value > 0.65 ? 1.3 - value : value,
          child: child,
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.progressTrack,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.progressTrack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
