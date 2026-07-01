import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

/// Match History screen — shows all of the user's sparring games with
/// result badges, move counts, duration, grandmaster info, and BKT
/// analysis status per match.
class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isAuthenticated) {
        state.fetchMatches();
      }
    });
  }

  Future<void> _refresh() => context.read<AppState>().fetchMatches();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Consumer<AppState>(
          builder: (context, state, _) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primaryBlue,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── App Bar ──────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Match History',
                                style: tt.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                'Your sparring record',
                                style: tt.bodySmall?.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (state.matchesLoading)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Stats summary row ─────────────────────────────────
                  if (!state.matchesLoading && state.matches != null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: _StatsRow(matches: state.matches!),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Match list ────────────────────────────────────────
                  if (state.matchesLoading && state.matches == null)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => const _MatchShimmer(),
                        childCount: 6,
                      ),
                    )
                  else if (state.matches == null || state.matches!.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _MatchCard(
                            match: state.matches![i],
                            index: i,
                          ),
                          childCount: state.matches!.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Stats Summary Row ──────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<dynamic> matches;
  const _StatsRow({required this.matches});

  @override
  Widget build(BuildContext context) {
    final total = matches.length;
    final wins = matches.where((m) => m['result'] == 'win').length;
    final losses = matches.where((m) => m['result'] == 'loss').length;
    final draws = matches.where((m) => m['result'] == 'draw').length;
    final analyzed = matches.where((m) {
      final blunders = m['blunder_categories'];
      return blunders != null;
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCell(value: '$total', label: 'Games', color: AppColors.primaryBlue),
          _divider(),
          _StatCell(value: '$wins', label: 'Wins', color: const Color(0xFF2E7D32)),
          _divider(),
          _StatCell(value: '$losses', label: 'Losses', color: AppColors.liveRed),
          _divider(),
          _StatCell(value: '$draws', label: 'Draws', color: const Color(0xFFFF8F00)),
          _divider(),
          _StatCell(value: '$analyzed', label: 'Analyzed', color: AppColors.primaryLight),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.border,
      );
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCell({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

// ── Individual Match Card ──────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final int index;

  const _MatchCard({required this.match, required this.index});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final result = match['result'] as String? ?? 'in_progress';
    final gm = match['grandmaster'] as Map<String, dynamic>?;
    final gmName = gm?['full_name'] as String? ?? 'Unknown GM';
    final gmStyle = gm?['style'] as String? ?? '';
    final moveCount = match['move_count'] as int? ?? 0;
    final durationSec = match['duration_seconds'] as int? ?? 0;
    final playedAt = _formatDate(match['played_at'] as String?);
    final hasAnalysis = match['blunder_categories'] != null;
    final eloChange = match['elo_change'] as int?;

    // Result styling
    final resultColor = _resultColor(result);
    final resultLabel = _resultLabel(result);
    final resultIcon = _resultIcon(result);

    // ELO chip
    final eloColor = eloChange == null
        ? AppColors.textLight
        : eloChange > 0
            ? const Color(0xFF2E7D32)
            : eloChange < 0
                ? AppColors.liveRed
                : AppColors.textLight;
    final eloSign = (eloChange ?? 0) > 0 ? '+' : '';

    // BKT analysis badge color
    final bktColor = hasAnalysis
        ? const Color(0xFF2E7D32)
        : result == 'in_progress'
            ? AppColors.textLight
            : const Color(0xFFFF8F00);
    final bktLabel = hasAnalysis
        ? 'BKT Analyzed'
        : result == 'in_progress'
            ? 'In Progress'
            : 'Pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  // Result badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: resultColor.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Icon(resultIcon, size: 20, color: resultColor),
                  ),
                  const SizedBox(width: 12),

                  // GM info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'vs GM $gmName',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gmStyle.isNotEmpty ? gmStyle : playedAt,
                          style: tt.bodySmall?.copyWith(
                            color: AppColors.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Result label + ELO change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          resultLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: resultColor,
                          ),
                        ),
                      ),
                      if (eloChange != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '$eloSign$eloChange',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: eloColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Meta row ──
              Row(
                children: [
                  _metaChip(
                    Icons.swap_horiz_rounded,
                    '$moveCount moves',
                    AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  if (durationSec > 0)
                    _metaChip(
                      Icons.timer_rounded,
                      _formatDuration(durationSec),
                      AppColors.textLight,
                    ),
                  const SizedBox(width: 8),
                  _metaChip(
                    Icons.calendar_today_rounded,
                    playedAt,
                    AppColors.textLight,
                  ),
                  const Spacer(),

                  // BKT analysis status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: bktColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasAnalysis
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          size: 10,
                          color: bktColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bktLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: bktColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Blunder breakdown (if analyzed) ──────────────────────
              if (hasAnalysis) ...[
                const SizedBox(height: 10),
                _BlunderBreakdown(
                    categories: match['blunder_categories'] as Map<String, dynamic>),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _resultColor(String result) {
    switch (result) {
      case 'win':
        return const Color(0xFF2E7D32);
      case 'loss':
        return AppColors.liveRed;
      case 'draw':
        return const Color(0xFFFF8F00);
      default:
        return AppColors.textLight;
    }
  }

  String _resultLabel(String result) {
    switch (result) {
      case 'win':
        return 'WIN';
      case 'loss':
        return 'LOSS';
      case 'draw':
        return 'DRAW';
      default:
        return 'IN PROGRESS';
    }
  }

  IconData _resultIcon(String result) {
    switch (result) {
      case 'win':
        return Icons.emoji_events_rounded;
      case 'loss':
        return Icons.flag_rounded;
      case 'draw':
        return Icons.handshake_rounded;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}

// ── Blunder Breakdown Bar ──────────────────────────────────────────────────────

class _BlunderBreakdown extends StatelessWidget {
  final Map<String, dynamic> categories;
  const _BlunderBreakdown({required this.categories});

  static const _skillLabels = {
    'tactical_oversight': 'Tactics',
    'positional_error': 'Position',
    'endgame_fundamentals': 'Endgame',
    'opening_theory': 'Opening',
    'king_safety': 'King Safety',
    'pawn_structure': 'Pawns',
    'time_management': 'Time',
    'calculation_error': 'Calculation',
  };

  @override
  Widget build(BuildContext context) {
    // Only show skills that had at least 1 blunder
    final active = categories.entries
        .where((e) => (e.value as int? ?? 0) > 0)
        .toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    if (active.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 13, color: Color(0xFF2E7D32)),
            SizedBox(width: 6),
            Text(
              'No blunders detected — clean game!',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final maxVal = (active.first.value as int).toDouble().clamp(1.0, 999.0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BLUNDER ANALYSIS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ...active.take(3).map((e) {
            final label =
                _skillLabels[e.key] ?? e.key.replaceAll('_', ' ');
            final count = e.value as int;
            final frac = count / maxVal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 6,
                        backgroundColor: AppColors.progressTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          frac > 0.6
                              ? AppColors.liveRed
                              : frac > 0.3
                                  ? const Color(0xFFFF8F00)
                                  : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.castle_rounded,
                size: 38,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No games yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Spar against a Grandmaster AI to\nstart building your match history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading Shimmer ────────────────────────────────────────────────────────────

class _MatchShimmer extends StatelessWidget {
  const _MatchShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.progressTrack,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 13,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.progressTrack,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppColors.progressTrack,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
