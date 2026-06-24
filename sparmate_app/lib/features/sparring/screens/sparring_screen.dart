import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/grandmaster.dart';
import '../widgets/gm_profile_card.dart';
import '../widgets/game_board_card.dart';
import '../widgets/game_info_card.dart';
import '../widgets/pressure_gauge.dart';

/// Sparring screen for playing against a specific Grandmaster AI persona.
class SparringScreen extends StatefulWidget {
  final Grandmaster gm;
  const SparringScreen({super.key, required this.gm});

  @override
  State<SparringScreen> createState() => _SparringScreenState();
}

class _SparringScreenState extends State<SparringScreen> {
  // Real-time pressure metrics (updated from engine analysis)
  double _pressure = 0.15;

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
                      'Spar with ${widget.gm.name}',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        fontSize: 20,
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

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GmProfileCard(gm: widget.gm),
                  const SizedBox(height: 12),
                  // ── Pressure Gauge (compact) ──
                  PressureGauge(
                    pressure: _pressure,
                    size: 80,
                  ),
                  const SizedBox(height: 12),
                  // ── Interactive Game Board ──
                  GameBoardCard(
                    gm: widget.gm,
                    onPressureChanged: (p) {
                      if (mounted) setState(() => _pressure = p);
                    },
                  ),
                  const SizedBox(height: 16),
                  GameInfoCard(gm: widget.gm),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

