import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/grandmaster.dart';
import 'sparring_screen.dart';

/// GM selection screen — choose which Grandmaster to spar against.
class GmSelectionScreen extends StatelessWidget {
  const GmSelectionScreen({super.key});

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
                      'Choose Opponent',
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

            // ── Subtitle ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Select a Grandmaster AI persona to begin your sparring session.',
                  style: tt.bodyMedium?.copyWith(color: AppColors.textMedium, height: 1.4),
                ),
              ),
            ),

            // ── GM Cards ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  Grandmaster.all.map((gm) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _GmSelectionCard(gm: gm),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GmSelectionCard extends StatelessWidget {
  final Grandmaster gm;
  const _GmSelectionCard({required this.gm});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SparringScreen(gm: gm)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: gm.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gm.color.withValues(alpha: 0.85), gm.color.withValues(alpha: 0.55)],
                ),
                border: Border.all(color: gm.color.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(color: gm.color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(gm.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${gm.title} ${gm.fullName}',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Text(gm.nationality, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    gm.style,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: gm.color),
                  ),
                  const SizedBox(height: 4),
                  // Strengths preview
                  Row(
                    children: gm.strengths.take(2).map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: gm.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(s, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: gm.color)),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),

            // ── ELO + Arrow ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${gm.eloRating}',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                Text('ELO', style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 24),
          ],
        ),
      ),
    );
  }
}
