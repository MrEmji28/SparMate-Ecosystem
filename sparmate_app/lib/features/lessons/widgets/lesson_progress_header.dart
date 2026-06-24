import 'package:flutter/material.dart';

/// Hero header showing lesson title, animated progress ring, and description.
/// Accepts dynamic data from the parent LessonDetailScreen.
class LessonProgressHeader extends StatefulWidget {
  final String title;
  final String description;
  final double progress;
  final String chapters;
  final double rating;
  final String timeLeft;
  final Color color;
  final IconData icon;

  const LessonProgressHeader({
    super.key,
    this.title = 'Sicilian Defense',
    this.description = 'Master the most popular chess opening.',
    this.progress = 0.65,
    this.chapters = '12 Chapters',
    this.rating = 4.8,
    this.timeLeft = '~45 min left',
    this.color = const Color(0xFF3949AB),
    this.icon = Icons.shield_rounded,
  });

  @override
  State<LessonProgressHeader> createState() => _LessonProgressHeaderState();
}

class _LessonProgressHeaderState extends State<LessonProgressHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(LessonProgressHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color,
            widget.color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE LESSON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.title,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              // Animated Progress ring
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) {
                  final animatedValue = widget.progress *
                      CurvedAnimation(
                        parent: _progressAnim,
                        curve: Curves.easeOutCubic,
                      ).value;

                  return SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: CircularProgressIndicator(
                            value: animatedValue,
                            strokeWidth: 5,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation(
                                Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${(widget.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _stat(Icons.menu_book_rounded, widget.chapters),
              const SizedBox(width: 20),
              _stat(Icons.timer_rounded, widget.timeLeft),
              const SizedBox(width: 20),
              _stat(Icons.star_rounded, '${widget.rating} Rating'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// AnimatedBuilder widget using AnimatedWidget pattern.
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimWidget(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class _AnimWidget extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimWidget({
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
