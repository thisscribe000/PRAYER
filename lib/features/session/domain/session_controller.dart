import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';

class SessionState {
  final Duration elapsed;
  final bool isRunning;

  const SessionState({
    required this.elapsed,
    required this.isRunning,
  });

  SessionState copyWith({
    Duration? elapsed,
    bool? isRunning,
  }) {
    return SessionState(
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController()
      : super(const SessionState(
          elapsed: Duration.zero,
          isRunning: false,
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

  void reset() {
    _timer?.cancel();
    state = const SessionState(
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
