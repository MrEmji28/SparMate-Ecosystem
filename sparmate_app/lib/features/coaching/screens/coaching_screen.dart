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
  bool _hasShownIntro = false;

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
          if (mounted) {
            _animController.forward();
            _maybeShowIntro();
          }
        });
      } else {
        _animController.forward();
        _maybeShowIntro();
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

  void _maybeShowIntro() {
    if (_hasShownIntro || !mounted) return;
    _hasShownIntro = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      _showCoachingIntroDialog(state);
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

  void _showCoachingIntroDialog(AppState state) {
    final directive =
        state.trainingPlan?['primary_directive'] as String? ??
            'Analyze your games to unlock personalized coaching.';
    // Extract skills map - try nested 'skills' key first, then flat
    Map<String, dynamic> bktSkills = {};
    try {
      final raw = state.bktMatrix;
      if (raw != null) {
        if (raw['skills'] is Map) {
          bktSkills = raw['skills'] as Map<String, dynamic>;
        } else {
          // Skills might be at top level
          bktSkills = Map<String, dynamic>.from(raw);
          // Remove non-skill keys
          bktSkills.remove('timestamp');
          bktSkills.remove('user_id');
        }
      }
    } catch (_) {}

    // Extract top weak skill
    String topSkill = 'Chess Skills';
    double topMastery = 1.0;
    try {
      bktSkills.forEach((key, value) {
        final mastery = (value is num) ? value.toDouble() : 1.0;
        if (mastery < topMastery) {
          topMastery = mastery;
          topSkill = key;
        }
      });
    } catch (_) {}

    final planItems =
        state.trainingPlan?['plan_items'] as List<dynamic>? ?? [];

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, secondAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: _CoachingIntroDialogContent(
              directive: directive,
              skillCount: bktSkills.length,
              focusSkill: topSkill,
              focusMastery: topMastery,
              planItemCount: planItems.length,
              onStart: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      },
    );
  }
}

/// ── Coaching Intro Dialog ─────────────────────────────────────────────
class _CoachingIntroDialogContent extends StatelessWidget {
  final String directive;
  final int skillCount;
  final String focusSkill;
  final double focusMastery;
  final int planItemCount;
  final VoidCallback onStart;

  const _CoachingIntroDialogContent({
    required this.directive,
    required this.skillCount,
    required this.focusSkill,
    required this.focusMastery,
    required this.planItemCount,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final masteryPct = (focusMastery * 100).round();
    final masteryLabel = masteryPct < 30
        ? 'Novice'
        : masteryPct < 50
            ? 'Developing'
            : masteryPct < 70
                ? 'Intermediate'
                : 'Advanced';
    final masteryColor = masteryPct < 30
        ? const Color(0xFFE53935)
        : masteryPct < 50
            ? const Color(0xFFFFA000)
            : masteryPct < 70
                ? const Color(0xFF1E88E5)
                : const Color(0xFF43A047);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Coach icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1565C0),
                        Color(0xFF42A5F5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Coaching Engine',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI-powered personalized training',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 20),

                // Primary directive quote
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote_rounded,
                          size: 20,
                          color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          directive,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                        Icons.analytics_rounded,
                        '$skillCount',
                        'Skills Tracked',
                        AppColors.primaryBlue,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.border,
                      ),
                      _statItem(
                        Icons.checklist_rounded,
                        '$planItemCount',
                        'Plan Items',
                        const Color(0xFF43A047),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.border,
                      ),
                      _statItem(
                        Icons.trending_up_rounded,
                        '$masteryPct%',
                        masteryLabel,
                        masteryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Focus area
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: masteryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: masteryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.gps_fixed_rounded,
                          size: 20, color: masteryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority Focus: ${_formatSkillName(focusSkill)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Mini progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: focusMastery,
                                backgroundColor:
                                    masteryColor.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation(masteryColor),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: masteryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$masteryPct%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: masteryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 22),
                        SizedBox(width: 8),
                        Text('Start Coaching'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Powered by Bayesian Knowledge Tracing',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSkillName(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _statItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
