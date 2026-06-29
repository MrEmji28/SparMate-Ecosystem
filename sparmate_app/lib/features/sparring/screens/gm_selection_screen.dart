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
                    if (Navigator.canPop(context))
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
      onTap: () => _showGmIntroDialog(context, gm),
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
                border: Border.all(color: gm.color.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(color: gm.color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  gm.imagePath,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: gm.color.withValues(alpha: 0.7),
                    child: Icon(gm.icon, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${gm.title} ${gm.fullName}',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: gm.strengths.take(2).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: gm.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: gm.color)),
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

  void _showGmIntroDialog(BuildContext context, Grandmaster gm) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, secondAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: _GmIntroDialogContent(gm: gm),
          ),
        );
      },
    );
  }
}

/// Compact intro dialog content for the selected Grandmaster.
/// Designed to fit on one screen without scrolling.
class _GmIntroDialogContent extends StatelessWidget {
  final Grandmaster gm;
  const _GmIntroDialogContent({required this.gm});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Center(
      child: Container(
        width: size.width * 0.88,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gm.color.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Colored Header (compact) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gm.color.withValues(alpha: 0.95),
                        gm.color.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            gm.imagePath,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white.withValues(alpha: 0.2),
                              child: Icon(gm.icon, size: 30, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Title badge + Nationality
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              gm.title,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            gm.nationality,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Full Name
                      Text(
                        gm.fullName,
                        textAlign: TextAlign.center,
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Style
                      Text(
                        gm.style,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Era + ELO pills (in header)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _headerPill(Icons.calendar_today_rounded, gm.era),
                          const SizedBox(width: 8),
                          _headerPill(Icons.bar_chart_rounded, 'ELO ${gm.eloRating}'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Body Content (compact) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Quote ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: gm.color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: gm.color.withValues(alpha: 0.4),
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          gm.quote,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMedium,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Style Description ──
                      Text(
                        gm.styleDescription,
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.textMedium,
                          height: 1.45,
                          fontSize: 12.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),

                      // ── Strengths (inline) ──
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: gm.strengths
                            .map((s) => _chip(s, gm.color))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Start Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // close dialog
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SparringScreen(gm: gm),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor: gm.color.withValues(alpha: 0.4),
                            backgroundColor: Colors.transparent,
                          ).copyWith(
                            overlayColor: WidgetStateProperty.all(
                              Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  gm.color,
                                  gm.color.withValues(alpha: 0.75),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.sports_mma_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Start Sparring',
                                    style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
