import 'dart:convert';
import 'package:http/http.dart' as http;

/// SparMate API Service — handles all HTTP communication with the
/// Laravel backend gateway (Sprint 8: Integration).
///
/// Provides typed methods for every Laravel API endpoint defined
/// in `sparmate_backend/routes/api.php`.
class ApiService {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8001/api/v1';
  // For Android emulator use: 'http://10.0.2.2:8001/api/v1'
  // For physical device use your machine's LAN IP

  final String baseUrl;
  String? _token;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  /// Set the Bearer token after login/register.
  void setToken(String token) => _token = token;

  /// Clear the token on logout.
  void clearToken() => _token = null;

  bool get isAuthenticated => _token != null;

  // ── HTTP Helpers ──────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(String path,
      [Map<String, dynamic>? body]) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _put(String path,
      [Map<String, dynamic>? body]) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      _token = null;
      throw ApiException('Unauthorized — please log in again.', 401);
    } else if (response.statusCode == 403) {
      throw ApiException('Forbidden — access denied.', 403);
    } else if (response.statusCode == 422) {
      final errors = jsonDecode(response.body);
      throw ApiException(
        errors['message'] ?? 'Validation failed.',
        422,
        validationErrors: errors['errors'] as Map<String, dynamic>?,
      );
    } else {
      throw ApiException(
        'Request failed with status ${response.statusCode}.',
        response.statusCode,
      );
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────

  /// Register a new user. Returns user data + token.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await _post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    _token = data['token'] as String?;
    return data;
  }

  /// Log in with email and password. Returns user data + token.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/login', {
      'email': email,
      'password': password,
    });
    _token = data['token'] as String?;
    return data;
  }

  /// Log out — invalidate the current token.
  Future<void> logout() async {
    try {
      await _post('/logout');
    } finally {
      _token = null;
    }
  }

  /// Get the currently authenticated user.
  Future<Map<String, dynamic>> getUser() => _get('/user');

  // ── Dashboard ─────────────────────────────────────────────────────

  /// Fetch the Home screen aggregate (stats, recent matches, etc.).
  Future<Map<String, dynamic>> getDashboard() => _get('/dashboard');

  // ── Grandmasters ──────────────────────────────────────────────────

  /// Fetch all grandmaster personas.
  Future<List<dynamic>> getGrandmasters() async {
    final data = await _get('/grandmasters');
    // The endpoint returns a JSON array at the root
    return data['data'] as List<dynamic>? ?? [];
  }

  /// Fetch a specific grandmaster by ID.
  Future<Map<String, dynamic>> getGrandmaster(int id) =>
      _get('/grandmasters/$id');

  // ── Lessons ───────────────────────────────────────────────────────

  /// Fetch all lessons (optionally filtered by category on the backend).
  Future<List<dynamic>> getLessons() async {
    final data = await _get('/lessons');
    return data['data'] as List<dynamic>? ?? [];
  }

  /// Fetch a specific lesson with chapters.
  Future<Map<String, dynamic>> getLesson(int id) => _get('/lessons/$id');

  /// Update lesson progress (mark chapter as completed).
  Future<Map<String, dynamic>> updateLessonProgress(
    int lessonId, {
    required int chapterId,
    required bool completed,
  }) =>
      _post('/lessons/$lessonId/progress', {
        'chapter_id': chapterId,
        'completed': completed,
      });

  // ── Sparring Matches ──────────────────────────────────────────────

  /// Fetch the user's match history.
  Future<List<dynamic>> getMatches() async {
    final data = await _get('/matches');
    return data['data'] as List<dynamic>? ?? [];
  }

  /// Start a new sparring match.
  Future<Map<String, dynamic>> createMatch({
    required int grandmasterId,
    required String color,
  }) =>
      _post('/matches', {
        'grandmaster_id': grandmasterId,
        'color': color,
      });

  /// Update an in-progress match (submit PGN, result, etc.).
  Future<Map<String, dynamic>> updateMatch(
    int matchId, {
    String? pgn,
    String? finalFen,
    String? result,
    int? moveCount,
    int? duration,
  }) =>
      _put('/matches/$matchId', {
        if (pgn != null) 'pgn': pgn,
        if (finalFen != null) 'fen_final': finalFen,
        if (result != null) 'result': result,
        if (moveCount != null) 'move_count': moveCount,
        if (duration != null) 'duration_seconds': duration,
      });

  /// Trigger post-game analysis (classifies blunders via FastAPI).
  Future<Map<String, dynamic>> analyzeMatch(int matchId) =>
      _post('/matches/$matchId/analyze');

  // ── Puzzles ───────────────────────────────────────────────────────

  /// Fetch today's daily puzzles.
  Future<Map<String, dynamic>> getDailyPuzzles() => _get('/puzzles/daily');

  /// Fetch recent puzzle attempts.
  Future<List<dynamic>> getRecentPuzzles() async {
    final data = await _get('/puzzles/recent');
    return data['data'] as List<dynamic>? ?? [];
  }

  /// Submit a puzzle attempt.
  Future<Map<String, dynamic>> submitPuzzleAttempt(
    int puzzleId, {
    required bool solved,
    required int timeTakenSeconds,
  }) =>
      _post('/puzzles/$puzzleId/attempt', {
        'solved': solved,
        'time_seconds': timeTakenSeconds,
      });

  // ── Coaching Engine ───────────────────────────────────────────────

  /// Fetch the user's current training plan + BKT matrix.
  Future<Map<String, dynamic>> getCoachingPlan() => _get('/coaching/plan');

  /// Trigger a coaching plan refresh (calls FastAPI under the hood).
  Future<Map<String, dynamic>> refreshCoachingPlan() =>
      _post('/coaching/refresh');

  /// Fetch the user's analytics overview.
  Future<Map<String, dynamic>> getAnalyticsOverview() =>
      _get('/analytics/overview');

  // ── BKT Recommendations ───────────────────────────────────────────

  /// Fetch BKT-driven lesson and puzzle recommendations.
  /// Returns weak_skills, recommended_lessons, recommended_puzzles, focus_message.
  Future<Map<String, dynamic>> getRecommendations() =>
      _get('/recommendations');

  // ── Onboarding ────────────────────────────────────────────────────

  /// Submit the onboarding skill survey answers.
  Future<Map<String, dynamic>> submitOnboarding(
      List<Map<String, dynamic>> answers) =>
      _post('/onboarding', {'answers': answers});
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? validationErrors;

  const ApiException(this.message, this.statusCode, {this.validationErrors});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
