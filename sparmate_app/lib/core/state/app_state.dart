import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Global application state managed via ChangeNotifier (Provider).
///
/// Holds authentication state, user data, BKT matrix, and coaching plan.
/// Screens listen to changes and rebuild automatically.
class AppState extends ChangeNotifier {
  final ApiService api;

  AppState({ApiService? api}) : api = api ?? ApiService();

  // ── Auth State ────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => api.isAuthenticated;

  /// True if the user has completed the onboarding skill survey.
  bool get onboardingCompleted =>
      _user?['onboarding_completed'] == true;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── BKT Matrix & Coaching ─────────────────────────────────────────

  Map<String, dynamic>? _bktMatrix;
  Map<String, dynamic>? get bktMatrix => _bktMatrix;

  Map<String, dynamic>? _trainingPlan;
  Map<String, dynamic>? get trainingPlan => _trainingPlan;

  List<dynamic>? _weakestSkills;
  List<dynamic>? get weakestSkills => _weakestSkills;

  /// Recent coaching indicators from match analysis (opponent, text, icon_type).
  List<dynamic>? _recentIndicators;
  List<dynamic>? get recentIndicators => _recentIndicators;

  /// Coaching-specific error message for graceful degradation.
  String? _coachingError;
  String? get coachingError => _coachingError;

  /// Timestamp of last coaching data fetch to avoid redundant calls.
  DateTime? _lastCoachingFetch;
  DateTime? get lastCoachingFetch => _lastCoachingFetch;

  // ── Dashboard ─────────────────────────────────────────────────────

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  // ── Analytics ─────────────────────────────────────────────────────

  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? get analyticsData => _analyticsData;

  // ── Grandmasters ──────────────────────────────────────────────────

  List<dynamic>? _grandmasters;
  List<dynamic>? get grandmasters => _grandmasters;

  // ── Lessons ───────────────────────────────────────────────────────

  List<dynamic>? _lessons;
  List<dynamic>? get lessons => _lessons;

  // ── Match History ─────────────────────────────────────────────────

  List<dynamic>? _matches;
  List<dynamic>? get matches => _matches;

  bool _matchesLoading = false;
  bool get matchesLoading => _matchesLoading;

  /// Fetch the user's match history from the backend.
  Future<void> fetchMatches() async {
    if (!isAuthenticated) return;
    _matchesLoading = true;
    notifyListeners();
    try {
      _matches = await api.getMatches();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _matchesLoading = false;
      notifyListeners();
    }
  }

  // ── Analytics ─────────────────────────────────────────────────────

  bool _analyticsLoading = false;
  bool get analyticsLoading => _analyticsLoading;

  /// Fetch the full analytics overview from the backend.
  /// Populates [analyticsData] consumed by AnalyticsScreen widgets.
  Future<void> fetchAnalytics() async {
    if (!isAuthenticated) return;
    _analyticsLoading = true;
    notifyListeners();
    try {
      final data = await api.getAnalyticsOverview();
      _analyticsData = data;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      // Network error — keep showing stale/fallback data
    } finally {
      _analyticsLoading = false;
      notifyListeners();
    }
  }

  // ── BKT Recommendations ───────────────────────────────────────────

  Map<String, dynamic>? _recommendationsData;
  Map<String, dynamic>? get recommendationsData => _recommendationsData;
  bool _recommendationsLoading = false;
  bool get recommendationsLoading => _recommendationsLoading;

  /// Fetch BKT-driven lesson + puzzle recommendations.
  /// Reads the user's live mastery matrix and returns content ranked
  /// by weakness — weakest skill first.
  Future<void> fetchRecommendations() async {
    if (!isAuthenticated) return;
    _recommendationsLoading = true;
    notifyListeners();
    try {
      _recommendationsData = await api.getRecommendations();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      // Network error — recommendations degrade gracefully
    } finally {
      _recommendationsLoading = false;
      notifyListeners();
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _coachingError = null;
    notifyListeners();
  }

  /// Register a new user account.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final data = await api.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _user = data['user'] as Map<String, dynamic>?;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  /// Log in with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final data = await api.login(email: email, password: password);
      _user = data['user'] as Map<String, dynamic>?;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  /// Log out and clear all cached state.
  Future<void> logout() async {
    await api.logout();
    _user = null;
    _bktMatrix = null;
    _trainingPlan = null;
    _weakestSkills = null;
    _recentIndicators = null;
    _coachingError = null;
    _lastCoachingFetch = null;
    _dashboardData = null;
    _analyticsData = null;
    _grandmasters = null;
    _lessons = null;
    _matches = null;
    notifyListeners();
  }

  /// Fetch the current user profile.
  Future<void> fetchUser() async {
    try {
      _user = await api.getUser();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  /// Fetch the dashboard aggregate data (Home screen).
  Future<void> fetchDashboard() async {
    try {
      _dashboardData = await api.getDashboard();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  /// Fetch the coaching plan (BKT matrix + training plan + recent indicators).
  Future<void> fetchCoachingPlan() async {
    _coachingError = null;
    try {
      final data = await api.getCoachingPlan();
      _bktMatrix = data['bkt_matrix'] as Map<String, dynamic>?;
      _trainingPlan = data['training_plan'] as Map<String, dynamic>?;
      _weakestSkills = data['weakest_skills'] as List<dynamic>?;
      _recentIndicators = data['recent_indicators'] as List<dynamic>?;
      _lastCoachingFetch = DateTime.now();
      notifyListeners();
    } on ApiException catch (e) {
      _coachingError = e.message;
      notifyListeners();
    }
  }

  /// Refresh the coaching plan (triggers FastAPI call).
  Future<void> refreshCoachingPlan() async {
    _setLoading(true);
    _coachingError = null;
    try {
      final data = await api.refreshCoachingPlan();
      _trainingPlan = data['training_plan'] as Map<String, dynamic>?;
      _recentIndicators = data['recent_indicators'] as List<dynamic>?;
      _setLoading(false);
      // Re-fetch the full coaching data to update BKT matrix
      await fetchCoachingPlan();
    } on ApiException catch (e) {
      _coachingError = e.message;
      _setLoading(false);
    }
  }


  /// Fetch all grandmaster personas.
  Future<void> fetchGrandmasters() async {
    try {
      _grandmasters = await api.getGrandmasters();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  /// Fetch all lessons.
  Future<void> fetchLessons() async {
    try {
      _lessons = await api.getLessons();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }


  /// Start a new sparring match and return the match data.
  Future<Map<String, dynamic>?> startMatch({
    required int grandmasterId,
    required String color,
  }) async {
    try {
      return await api.createMatch(
        grandmasterId: grandmasterId,
        color: color,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Complete a match and trigger post-game analysis.
  ///
  /// Returns the analysis map which includes:
  ///   - `rating_change`  (int, signed)
  ///   - `new_rating`     (int)
  ///   - `old_rating`     (int)
  ///   - `classified_blunders`, `new_matrix`, etc.
  Future<Map<String, dynamic>?> completeMatch(
    int matchId, {
    required String pgn,
    required String finalFen,
    required String result,
    required int moveCount,
    required int duration,
  }) async {
    _setLoading(true);
    try {
      // Step 1: Submit the match result
      await api.updateMatch(
        matchId,
        pgn: pgn,
        finalFen: finalFen,
        result: result,
        moveCount: moveCount,
        duration: duration,
      );

      // Step 2: Trigger blunder analysis + ELO update (Laravel → FastAPI)
      final analysis = await api.analyzeMatch(matchId);

      // Step 3: Update local user ELO immediately so every widget reflects it
      final newRating = analysis['new_rating'] as int?;
      if (newRating != null && _user != null) {
        _user = Map<String, dynamic>.from(_user!)
          ..['elo_rating'] = newRating;
        notifyListeners();
      }

      // Step 4: Refresh the coaching plan with updated BKT matrix
      await fetchCoachingPlan();

      // Step 5: Refresh match history so History tab shows the new game
      unawaited(fetchMatches());

      _setLoading(false);
      return analysis;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return null;
    }
  }

  /// Submit onboarding skill survey answers.
  /// Updates the user's ELO rating and BKT matrix based on responses.
  Future<bool> submitOnboarding(List<Map<String, dynamic>> answers) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final data = await api.submitOnboarding(answers);
      _user = (data['user'] as Map<String, dynamic>?) ?? _user;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }
}
