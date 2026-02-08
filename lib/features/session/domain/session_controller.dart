import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

final sessionProvider = StateNotifierProvider<SessionController, SessionState>(
  (ref) => SessionController(),
);

class PrayerSession {
  final Duration duration;
  final DateTime date;

  PrayerSession({
    required this.duration,
    required this.date,
  });
}

class PrayerProject {
  final String id;
  final String name;
  final List<PrayerSession> sessions;

  PrayerProject({
    required this.id,
    required this.name,
    required this.sessions,
  });

  Duration get total {
    return sessions.fold(
      Duration.zero,
      (previous, element) => previous + element.duration,
    );
  }

  DateTime? get lastSessionDate {
    if (sessions.isEmpty) return null;
    final copy = [...sessions]..sort((a, b) => a.date.compareTo(b.date));
    return copy.last.date;
  }

  PrayerProject copyWith({
    String? id,
    String? name,
    List<PrayerSession>? sessions,
  }) {
    return PrayerProject(
      id: id ?? this.id,
      name: name ?? this.name,
      sessions: sessions ?? this.sessions,
    );
  }
}

class SessionState {
  final Duration elapsed;
  final bool isRunning;
  final List<PrayerProject> projects;
  final String selectedProjectId;

  SessionState({
    required this.elapsed,
    required this.isRunning,
    required this.projects,
    required this.selectedProjectId,
  });

  SessionState copyWith({
    Duration? elapsed,
    bool? isRunning,
    List<PrayerProject>? projects,
    String? selectedProjectId,
  }) {
    return SessionState(
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
      projects: projects ?? this.projects,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController()
      : super(
          SessionState(
            elapsed: Duration.zero,
            isRunning: false,
            projects: const [],
            selectedProjectId: "",
          ),
        ) {
    _loadProjects();
    _restoreRunState(); // ✅ restore persisted timer state
  }

  Timer? _ticker;

  // ---------------- PERSISTENT RUN STATE ----------------
  static const String _runBoxName = 'sessionBox';
  static const String _kIsRunning = 'isRunning';
  static const String _kStartedAtMs = 'startedAtMs';
  static const String _kBaseElapsedSec = 'baseElapsedSec';

  Box get _runBox => Hive.box(_runBoxName);

  void _saveRunState({
    required bool isRunning,
    int? startedAtMs,
    required int baseElapsedSec,
  }) {
    // fire-and-forget but ensure flush request is made
    unawaited(_runBox.put(_kIsRunning, isRunning));
    unawaited(_runBox.put(_kStartedAtMs, startedAtMs));
    unawaited(_runBox.put(_kBaseElapsedSec, baseElapsedSec));
    unawaited(_runBox.flush());
  }

  void _clearRunState() {
    _saveRunState(isRunning: false, startedAtMs: null, baseElapsedSec: 0);
  }

  Duration _computeElapsedNow() {
    final isRunning = (_runBox.get(_kIsRunning) as bool?) ?? false;
    final startedAtMs = (_runBox.get(_kStartedAtMs) as int?) ?? 0;
    final baseElapsedSec = (_runBox.get(_kBaseElapsedSec) as int?) ?? 0;

    final base = Duration(seconds: baseElapsedSec);

    if (!isRunning || startedAtMs <= 0) return base;

    final startedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMs);
    final diff = DateTime.now().difference(startedAt);
    return base + diff;
  }

  void _restoreRunState() {
    final isRunning = (_runBox.get(_kIsRunning) as bool?) ?? false;
    final elapsed = _computeElapsedNow();

    state = state.copyWith(
      isRunning: isRunning,
      elapsed: elapsed,
    );

    if (isRunning) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isRunning) return;
      state = state.copyWith(elapsed: _computeElapsedNow());
    });
  }

  // ---------------- ANALYTICS (used by Home screen) ----------------

  Duration get todayTotal {
    final now = DateTime.now();
    final todaySessions = state.projects
        .expand((p) => p.sessions)
        .where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day);

    return todaySessions.fold(
      Duration.zero,
      (prev, e) => prev + e.duration,
    );
  }

  Duration get weekTotal {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final weekSessions = state.projects
        .expand((p) => p.sessions)
        .where((s) => s.date.isAfter(startOfWeek));

    return weekSessions.fold(
      Duration.zero,
      (prev, e) => prev + e.duration,
    );
  }

  // ---------------- LOAD / SAVE PROJECTS ----------------

  void _loadProjects() {
    final box = Hive.box('projectsBox');
    final saved = box.get('projects');

    if (saved == null) {
      // start empty (no placeholder)
      state = state.copyWith(projects: const [], selectedProjectId: "");
      return;
    }

    final loadedProjects = (saved as List)
        .map((e) {
          final map = Map<String, dynamic>.from(e);

          return PrayerProject(
            id: map['id'],
            name: map['name'],
            sessions: (map['sessions'] as List).map((s) {
              final sessionMap = Map<String, dynamic>.from(s);
              return PrayerSession(
                duration: Duration(seconds: sessionMap['duration']),
                date: DateTime.parse(sessionMap['date']),
              );
            }).toList(),
          );
        })
        .toList();

    if (loadedProjects.isEmpty) {
      state = state.copyWith(projects: const [], selectedProjectId: "");
      return;
    }

    // ✅ select last "deposited into" (most recent session), else last created
    final withSessions = loadedProjects.where((p) => p.sessions.isNotEmpty).toList();

    String selectedId;
    if (withSessions.isNotEmpty) {
      withSessions.sort((a, b) => a.lastSessionDate!.compareTo(b.lastSessionDate!));
      selectedId = withSessions.last.id;
    } else {
      selectedId = loadedProjects.last.id;
    }

    state = state.copyWith(
      projects: loadedProjects,
      selectedProjectId: selectedId,
    );
  }

  void _saveProjects() {
    final box = Hive.box('projectsBox');

    final serialized = state.projects.map((p) {
      return {
        'id': p.id,
        'name': p.name,
        'sessions': p.sessions.map((s) {
          return {
            'duration': s.duration.inSeconds,
            'date': s.date.toIso8601String(),
          };
        }).toList(),
      };
    }).toList();

    box.put('projects', serialized);
  }

  // ---------------- TIMER CONTROLS ----------------

  void start() {
    if (state.isRunning) return;
    if (state.selectedProjectId.isEmpty) return; // must have an account

    final baseElapsedSec = state.elapsed.inSeconds;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    _saveRunState(
      isRunning: true,
      startedAtMs: nowMs,
      baseElapsedSec: baseElapsedSec,
    );

    state = state.copyWith(isRunning: true);
    _startTicker();
  }

  void pause() {
    if (!state.isRunning) return;

    final frozen = _computeElapsedNow();
    _ticker?.cancel();

    _saveRunState(
      isRunning: false,
      startedAtMs: null,
      baseElapsedSec: frozen.inSeconds,
    );

    state = state.copyWith(isRunning: false, elapsed: frozen);
  }

  void end() {
    // freeze if running so we capture accurate elapsed
    if (state.isRunning) {
      pause();
    }

    if (state.elapsed == Duration.zero) {
      _clearRunState();
      state = state.copyWith(isRunning: false, elapsed: Duration.zero);
      return;
    }

    if (state.selectedProjectId.isEmpty) {
      _clearRunState();
      state = state.copyWith(isRunning: false, elapsed: Duration.zero);
      return;
    }

    final newSession = PrayerSession(
      duration: state.elapsed,
      date: DateTime.now(),
    );

    final updatedProjects = state.projects.map((project) {
      if (project.id == state.selectedProjectId) {
        return project.copyWith(
          sessions: [...project.sessions, newSession],
        );
      }
      return project;
    }).toList();

    state = state.copyWith(
      projects: updatedProjects,
      elapsed: Duration.zero,
      isRunning: false,
      selectedProjectId: state.selectedProjectId, // stay on same account
    );

    _clearRunState();
    _saveProjects();
  }

  // ---------------- ACCOUNT MANAGEMENT (used by Bank + PrayNow) ----------------

  void selectProject(String id) {
    final exists = state.projects.any((p) => p.id == id);
    if (!exists) return;
    state = state.copyWith(selectedProjectId: id);
  }

  void createProject(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final newProject = PrayerProject(
      id: const Uuid().v4(),
      name: trimmed,
      sessions: [],
    );

    state = state.copyWith(
      projects: [...state.projects, newProject],
      selectedProjectId: newProject.id,
    );

    _saveProjects();
  }

  void deleteProject(String id) {
    final updated = state.projects.where((p) => p.id != id).toList();

    if (updated.isEmpty) {
      state = state.copyWith(projects: const [], selectedProjectId: "");
      _saveProjects();
      return;
    }

    state = state.copyWith(
      projects: updated,
      selectedProjectId: updated.last.id,
    );

    _saveProjects();
  }

  // ✅ IMPORTANT: keep PrayNowScreen unchanged (it assumes non-null)
  PrayerProject get currentProject {
    if (state.projects.isEmpty || state.selectedProjectId.isEmpty) {
      return PrayerProject(id: "", name: "Open an Account", sessions: []);
    }

    for (final p in state.projects) {
      if (p.id == state.selectedProjectId) return p;
    }

    return state.projects.isNotEmpty
        ? state.projects.last
        : PrayerProject(id: "", name: "Open an Account", sessions: []);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
