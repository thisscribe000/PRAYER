import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';

class SessionState {
  final Duration elapsed;
  final bool isRunning;
  final List<Duration> sessions;

  const SessionState({
    required this.elapsed,
    required this.isRunning,
    required this.sessions,
  });

  Duration get todayTotal => sessions.fold(Duration.zero, (a, b) => a + b);

  SessionState copyWith({
    Duration? elapsed,
    bool? isRunning,
    List<Duration>? sessions,
  }) {
    return SessionState(
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
      sessions: sessions ?? this.sessions,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController()
      : super(const SessionState(
          elapsed: Duration.zero,
          isRunning: false,
          sessions: [],
        ));

  Timer? _timer;

  void start() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      );
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// End session: save it + reset timer
  void reset() {
    _timer?.cancel();

    if (state.elapsed > Duration.zero) {
      state = state.copyWith(
        sessions: [...state.sessions, state.elapsed],
      );
    }

    state = state.copyWith(
      elapsed: Duration.zero,
      isRunning: false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionController, SessionState>(
  (ref) => SessionController(),
);
