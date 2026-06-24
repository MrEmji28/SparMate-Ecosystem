import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

/// Onboarding skill survey — 5 chess-themed questions to determine
/// the user's skill level (beginner/intermediate/advanced).
///
/// Results are sent to `POST /api/v1/onboarding` which adjusts the
/// user's ELO rating and BKT mastery matrix accordingly.
class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Store selected answer for each question (null = not answered yet)
  final List<String?> _answers = List.filled(5, null);

  static const List<_SurveyQuestion> _questions = [
    _SurveyQuestion(
      id: 1,
      emoji: '♟️',
      title: 'How would you describe your chess experience?',
      subtitle: 'Be honest — this helps us personalize your training!',
      options: [
        _SurveyOption(
          value: 'beginner',
          label: 'Beginner',
          description: "I'm just learning how to play",
          icon: Icons.emoji_events_outlined,
        ),
        _SurveyOption(
          value: 'intermediate',
          label: 'Intermediate',
          description: 'I know the rules and basic strategies',
          icon: Icons.trending_up_rounded,
        ),
        _SurveyOption(
          value: 'advanced',
          label: 'Advanced',
          description: 'I study openings, tactics, and endgames regularly',
          icon: Icons.star_rounded,
        ),
      ],
    ),
    _SurveyQuestion(
      id: 2,
      emoji: '♞',
      title: 'How well do you know the chess pieces?',
      subtitle: 'Including special moves like castling and en passant',
      options: [
        _SurveyOption(
          value: 'learning',
          label: 'Still Learning',
          description: "I'm not sure how all pieces move",
          icon: Icons.school_outlined,
        ),
        _SurveyOption(
          value: 'most',
          label: 'Know Most',
          description: 'I know the basics, but special rules are tricky',
          icon: Icons.lightbulb_outline_rounded,
        ),
        _SurveyOption(
          value: 'all',
          label: 'Know Everything',
          description: 'All pieces, special moves, and rules — no problem',
          icon: Icons.verified_rounded,
        ),
      ],
    ),
    _SurveyQuestion(
      id: 3,
      emoji: '⏱️',
      title: 'How often do you play chess?',
      subtitle: 'Online or over the board — both count!',
      options: [
        _SurveyOption(
          value: 'never',
          label: 'Rarely or Never',
          description: "I've played a few games at most",
          icon: Icons.hourglass_empty_rounded,
        ),
        _SurveyOption(
          value: 'few',
          label: 'A Few Times a Month',
          description: 'I play casually when I get the chance',
          icon: Icons.calendar_month_rounded,
        ),
        _SurveyOption(
          value: 'regularly',
          label: 'Multiple Times a Week',
          description: 'Chess is part of my routine',
          icon: Icons.local_fire_department_rounded,
        ),
      ],
    ),
    _SurveyQuestion(
      id: 4,
      emoji: '⚔️',
      title: 'How familiar are you with chess tactics?',
      subtitle: 'Pins, forks, skewers, discovered attacks...',
      options: [
        _SurveyOption(
          value: 'none',
          label: 'Not Familiar',
          description: "I don't know what these terms mean",
          icon: Icons.help_outline_rounded,
        ),
        _SurveyOption(
          value: 'some',
          label: 'Somewhat Familiar',
          description: 'I recognize some patterns but miss them in games',
          icon: Icons.psychology_outlined,
        ),
        _SurveyOption(
          value: 'confident',
          label: 'Very Confident',
          description: 'I can spot tactics and use them to win',
          icon: Icons.bolt_rounded,
        ),
      ],
    ),
    _SurveyQuestion(
      id: 5,
      emoji: '🏆',
      title: 'Have you played in any tournaments?',
      subtitle: 'School events, club games, or online rated matches',
      options: [
        _SurveyOption(
          value: 'never',
          label: 'Never',
          description: "I've only played casual games",
          icon: Icons.sports_esports_outlined,
        ),
        _SurveyOption(
          value: 'casual',
          label: 'Casual Events',
          description: "A few school or club tournaments",
          icon: Icons.groups_rounded,
        ),
        _SurveyOption(
          value: 'competitive',
          label: 'Competitive',
          description: 'Regular tournaments with rated games',
          icon: Icons.emoji_events_rounded,
        ),
      ],
    ),
  ];

  void _selectAnswer(String value) {
    setState(() {
      _answers[_currentPage] = value;
    });
  }

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submitSurvey();
    }
  }

  Future<void> _submitSurvey() async {
    final answers = <Map<String, dynamic>>[];
    for (int i = 0; i < _questions.length; i++) {
      answers.add({
        'question_id': _questions[i].id,
        'answer': _answers[i]!,
      });
    }

    final state = context.read<AppState>();
    final success = await state.submitOnboarding(answers);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Failed to save survey.'),
          backgroundColor: AppColors.liveRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    // On success, AppState.onboardingCompleted becomes true,
    // and AuthGate will auto-navigate to AppShell.
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1137),
              Color(0xFF1B2063),
              Color(0xFF2A3BB7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Progress Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Question ${_currentPage + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_currentPage + 1} of ${_questions.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _questions.length,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentBlue,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Question Pages ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) =>
                      setState(() => _currentPage = page),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionPage(_questions[index], index);
                  },
                ),
              ),

              // ── Bottom Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: Key('survey-next-$_currentPage'),
                    onPressed: _answers[_currentPage] != null && !state.isLoading
                        ? _nextPage
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      disabledBackgroundColor:
                          AppColors.accentBlue.withValues(alpha: 0.3),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.4),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentPage == _questions.length - 1
                                ? 'Finish & Start Training'
                                : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(_SurveyQuestion question, int index) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji
          Text(
            question.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            question.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            question.subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Options
          ...question.options.map((option) {
            final isSelected = _answers[index] == option.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectAnswer(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentBlue.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentBlue
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentBlue.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          option.icon,
                          color: isSelected
                              ? AppColors.accentBlue
                              : Colors.white.withValues(alpha: 0.5),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              option.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Checkbox indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.accentBlue
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentBlue
                                : Colors.white.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Model for a survey question.
class _SurveyQuestion {
  final int id;
  final String emoji;
  final String title;
  final String subtitle;
  final List<_SurveyOption> options;

  const _SurveyQuestion({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.options,
  });
}

/// Model for a survey option.
class _SurveyOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const _SurveyOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}
