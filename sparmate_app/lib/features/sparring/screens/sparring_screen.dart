import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../models/grandmaster.dart';
import '../widgets/gm_profile_card.dart';
import '../widgets/game_board_card.dart';
import '../widgets/game_info_card.dart';
import '../widgets/pressure_gauge.dart';

/// Sparring screen — plays against a specific Grandmaster AI persona.
///
/// On load it calls [AppState.startMatch] to register the game on the
/// backend. The returned [matchId] is forwarded to [GameBoardCard] so that
/// when the game ends the full BKT pipeline runs automatically:
///   POST /matches/{id}/analyze → FastAPI classifies blunders
///   → BKT matrix updated → coaching plan refreshed
class SparringScreen extends StatefulWidget {
  final Grandmaster gm;
  const SparringScreen({super.key, required this.gm});

  @override
  State<SparringScreen> createState() => _SparringScreenState();
}

class _SparringScreenState extends State<SparringScreen> {
  // Pressure metric updated live from the engine
  double _pressure = 0.15;

  // 0 = Easy, 1 = Medium, 2 = Hard — drives AI move selection
  int _difficulty = 1;

  // The backend match ID — set once startMatch() succeeds
  int _matchId = 0;

  // State of the match-creation request
  _MatchCreateStatus _matchStatus = _MatchCreateStatus.loading;

  @override
  void initState() {
    super.initState();
    _createBackendMatch();
  }

  /// Call Laravel POST /matches to register this game session.
  /// Stores the returned id so GameBoardCard can trigger the BKT pipeline.
  Future<void> _createBackendMatch() async {
    final state = context.read<AppState>();

    // Only attempt if the user is authenticated
    if (!state.isAuthenticated) {
      if (mounted) setState(() => _matchStatus = _MatchCreateStatus.skipped);
      return;
    }

    try {
      final result = await state.startMatch(
        grandmasterId: widget.gm.id,
        color: 'white',
      );
      if (!mounted) return;

      if (result != null) {
        final id = result['match']?['id'] as int? ??
            result['id'] as int? ??
            0;
        setState(() {
          _matchId = id;
          _matchStatus = id > 0
              ? _MatchCreateStatus.ready
              : _MatchCreateStatus.skipped;
        });
      } else {
        setState(() => _matchStatus = _MatchCreateStatus.skipped);
      }
    } catch (_) {
      if (mounted) setState(() => _matchStatus = _MatchCreateStatus.skipped);
    }
  }

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
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.primaryNavy),
                      splashRadius: 22,
                    ),
                    Text(
                      'Spar with ${widget.gm.name}',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    // BKT-ready indicator
                    _buildMatchStatusBadge(),
                    const SizedBox(width: 8),
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
                      child:
                          const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GmProfileCard(gm: widget.gm),
                  const SizedBox(height: 12),
                  PressureGauge(pressure: _pressure, size: 80),
                  const SizedBox(height: 12),
                  // Pass matchId — 0 means BKT is skipped gracefully
                  GameBoardCard(
                    gm: widget.gm,
                    matchId: _matchId,
                    difficulty: _difficulty,
                    onPressureChanged: (p) {
                      if (mounted) setState(() => _pressure = p);
                    },
                  ),
                  const SizedBox(height: 16),
                  GameInfoCard(
                    gm: widget.gm,
                    onDifficultyChanged: (d) {
                      if (mounted) setState(() => _difficulty = d);
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small badge in the app bar showing BKT-tracking status.
  Widget _buildMatchStatusBadge() {
    switch (_matchStatus) {
      case _MatchCreateStatus.loading:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryBlue,
          ),
        );
      case _MatchCreateStatus.ready:
        return Tooltip(
          message: 'BKT tracking active — match #$_matchId',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'BKT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      case _MatchCreateStatus.skipped:
        return Tooltip(
          message: 'Practice mode — coaching data will not be saved',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'PRACTICE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
    }
  }
}

enum _MatchCreateStatus { loading, ready, skipped }
