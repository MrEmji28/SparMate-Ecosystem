import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../sparring/models/grandmaster.dart';
import '../../sparring/screens/sparring_screen.dart';
import '../../sparring/screens/gm_selection_screen.dart';

/// The hero "Spar with Grandmasters" card with LIVE badge,
/// grandmaster avatar row, and "Start Session" CTA.
class GrandmasterHeroCard extends StatelessWidget {
  const GrandmasterHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Spar with Grandmasters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _liveBadge(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Engage with tailored AI personas: Torre, Tal, Petrosian, or Carlsen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 18),

            // ── Grandmaster avatars (tappable → direct to sparring) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: Grandmaster.all.map((gm) => _avatarChip(context, gm)).toList(),
            ),
            const SizedBox(height: 20),

            // ── CTA Button → GM selection ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GmSelectionScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Start Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.liveRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarChip(BuildContext context, Grandmaster gm) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SparringScreen(gm: gm)),
        ),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gm.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  gm.imagePath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) {
                    debugPrint('Image load error for ${gm.imagePath}: $error');
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            gm.color.withValues(alpha: 0.9),
                            gm.color.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: Icon(gm.icon, color: Colors.white, size: 24),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              gm.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
