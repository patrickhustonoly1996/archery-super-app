import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of sessions that can be paused
enum ActiveSessionType {
  scoring,
  bowTraining,
  breathHold,
  pacedBreathing,
  patrickBreath,
}

/// Represents a paused/active session that can be resumed
class ActiveSession {
  final ActiveSessionType type;
  final String id;
  final String title;
  final String? subtitle;
  final DateTime pausedAt;
  final Map<String, dynamic> state;

  ActiveSession({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    required this.pausedAt,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'pausedAt': pausedAt.toIso8601String(),
    'state': state,
  };

  factory ActiveSession.fromJson(Map<String, dynamic> json) => ActiveSession(
    type: ActiveSessionType.values[json['type'] as int],
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String?,
    pausedAt: DateTime.parse(json['pausedAt'] as String),
    state: Map<String, dynamic>.from(json['state'] as Map),
  );
}

/// Central provider for tracking all active/paused sessions
/// Persists to SharedPreferences so sessions survive app restart
class ActiveSessionsProvider extends ChangeNotifier {
  static const String _storageKey = 'active_sessions';

  Map<ActiveSessionType, ActiveSession> _sessions = {};

  Map<ActiveSessionType, ActiveSession> get sessions => Map.unmodifiable(_sessions);

  bool get hasAnySessions => _sessions.isNotEmpty;

  ActiveSession? getSession(ActiveSessionType type) => _sessions[type];

  bool hasSession(ActiveSessionType type) => _sessions.containsKey(type);

  /// Load persisted sessions from storage
  Future<void> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(json);
        _sessions = {};
        data.forEach((key, value) {
          final type = ActiveSessionType.values[int.parse(key)];
          _sessions[type] = ActiveSession.fromJson(value);
        });
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading active sessions: $e');
      }
    }
  }

  /// Save sessions to storage
  Future<void> _persistSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    _sessions.forEach((type, session) {
      data[type.index.toString()] = session.toJson();
    });
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// Pause a session and save its state
  Future<void> pauseSession({
    required ActiveSessionType type,
    required String id,
    required String title,
    String? subtitle,
    required Map<String, dynamic> state,
  }) async {
    _sessions[type] = ActiveSession(
      type: type,
      id: id,
      title: title,
      subtitle: subtitle,
      pausedAt: DateTime.now(),
      state: state,
    );
    await _persistSessions();
    notifyListeners();
  }

  /// Resume a session (get its state and remove from paused)
  Future<ActiveSession?> resumeSession(ActiveSessionType type) async {
    final session = _sessions.remove(type);
    if (session != null) {
      await _persistSessions();
      notifyListeners();
    }
    return session;
  }

  /// Clear a session without resuming (user abandoned it)
  Future<void> clearSession(ActiveSessionType type) async {
    if (_sessions.remove(type) != null) {
      await _persistSessions();
      notifyListeners();
    }
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    _sessions.clear();
    await _persistSessions();
    notifyListeners();
  }

  /// Get display icon for session type
  static String getIconForType(ActiveSessionType type) {
    switch (type) {
      case ActiveSessionType.scoring:
        return 'target';
      case ActiveSessionType.bowTraining:
        return 'bow';
      case ActiveSessionType.breathHold:
      case ActiveSessionType.pacedBreathing:
      case ActiveSessionType.patrickBreath:
        return 'lungs';
    }
  }

  /// Get display name for session type
  static String getLabelForType(ActiveSessionType type) {
    switch (type) {
      case ActiveSessionType.scoring:
        return 'SCORE';
      case ActiveSessionType.bowTraining:
        return 'BOW DRILLS';
      case ActiveSessionType.breathHold:
        return 'BREATH HOLD';
      case ActiveSessionType.pacedBreathing:
        return 'PACED BREATHING';
      case ActiveSessionType.patrickBreath:
        return 'LONG EXHALE';
    }
  }
}
