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
  }

  Timer? _timer;

  // ---------------- ANALYTICS ----------------

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
      (prev, element) => prev + element.duration,
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
      (prev, element) => prev + element.duration,
    );
  }

  PrayerProject _defaultProject() {
    return PrayerProject(
      id: const Uuid().v4(),
      name: "General",
      sessions: [],
    );
  }

  // ---------------- LOAD ----------------

  void _loadProjects() {
    final box = Hive.box('projectsBox');
    final saved = box.get('projects');

    if (saved != null) {
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

      // ✅ Safety: if saved list is empty, create default
      if (loadedProjects.isEmpty) {
        final d = _defaultProject();
        state = state.copyWith(
          projects: [d],
          selectedProjectId: d.id,
        );
        _saveProjects();
        return;
      }

      // ✅ Safety: selectedProjectId must always be valid
      final selected = loadedProjects.first.id;

      state = state.copyWith(
        projects: loadedProjects,
        selectedProjectId: selected,
      );
    } else {
      final d = _defaultProject();
      state = state.copyWith(
        projects: [d],
        selectedProjectId: d.id,
      );
      _saveProjects();
    }
  }

  // ---------------- SAVE ----------------

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

  // ---------------- TIMER ----------------

  void start() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        state = state.copyWith(
          elapsed: state.elapsed + const Duration(seconds: 1),
        );
      },
    );
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void end() {
    _timer?.cancel();

    if (state.elapsed == Duration.zero) {
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
    );

    _saveProjects();
  }

  // ---------------- PROJECT MANAGEMENT ----------------

  void selectProject(String id) {
    // ✅ ignore invalid selection
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
      selectedProjectId: newProject.id, // ✅ select new one
    );

    _saveProjects();
  }

  void deleteProject(String id) {
    if (state.projects.length <= 1) return;

    final updated = state.projects.where((p) => p.id != id).toList();

    // ✅ Safety: ensure at least 1 remains
    if (updated.isEmpty) {
      final d = _defaultProject();
      state = state.copyWith(projects: [d], selectedProjectId: d.id);
      _saveProjects();
      return;
    }

    final newSelected = updated.first.id;

    state = state.copyWith(
      projects: updated,
      selectedProjectId: newSelected,
    );

    _saveProjects();
  }

  PrayerProject get currentProject {
    return state.projects.firstWhere(
      (p) => p.id == state.selectedProjectId,
      orElse: () => state.projects.isNotEmpty ? state.projects.first : _defaultProject(),
    );
  }
}
