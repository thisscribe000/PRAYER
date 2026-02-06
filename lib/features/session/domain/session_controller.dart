import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

final sessionProvider =
    StateNotifierProvider<SessionController, SessionState>(
  (ref) => SessionController(),
);

class PrayerProject {
  final String id;
  final String name;
  final List<Duration> sessions;

  PrayerProject({
    required this.id,
    required this.name,
    required this.sessions,
  });

  Duration get total {
    return sessions.fold(
      Duration.zero,
      (previous, element) => previous + element,
    );
  }

  PrayerProject copyWith({
    String? id,
    String? name,
    List<Duration>? sessions,
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
      selectedProjectId:
          selectedProjectId ?? this.selectedProjectId,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController()
      : super(
          SessionState(
            elapsed: Duration.zero,
            isRunning: false,
            projects: [
              PrayerProject(
                id: const Uuid().v4(),
                name: "General",
                sessions: [],
              ),
            ],
            selectedProjectId: "",
          ),
        ) {
    // Automatically select the default project
    state = state.copyWith(
      selectedProjectId: state.projects.first.id,
    );
  }

  Timer? _timer;

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
      state = state.copyWith(
        isRunning: false,
        elapsed: Duration.zero,
      );
      return;
    }

    final updatedProjects = state.projects.map((project) {
      if (project.id == state.selectedProjectId) {
        return project.copyWith(
          sessions: [...project.sessions, state.elapsed],
        );
      }
      return project;
    }).toList();

    state = state.copyWith(
      projects: updatedProjects,
      elapsed: Duration.zero,
      isRunning: false,
    );
  }

  void selectProject(String id) {
    state = state.copyWith(selectedProjectId: id);
  }

  PrayerProject get currentProject {
    return state.projects.firstWhere(
      (p) => p.id == state.selectedProjectId,
    );
  }

  void createProject(String name) {
  final newProject = PrayerProject(
    id: const Uuid().v4(),
    name: name,
    sessions: [],
  );

  state = state.copyWith(
    projects: [...state.projects, newProject],
  );
}

}
