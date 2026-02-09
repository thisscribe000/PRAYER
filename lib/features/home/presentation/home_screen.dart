import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../session/domain/session_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    final hasAccounts = session.projects.isNotEmpty;

    final currentProject = hasAccounts
        ? session.projects.firstWhere(
            (p) => p.id == session.selectedProjectId,
            orElse: () => session.projects.first,
          )
        : null;

    // Compute totals safely (no dependency on controller.todayTotal/weekTotal)
    final todayTotal = _computeTodayTotal(session);
    final weekTotal = _computeWeekTotal(session);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pray With Me',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today"),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(todayTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text("This Week"),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(weekTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text("Current Account"),
                      const SizedBox(height: 4),
                      Text(
                        hasAccounts ? _formatDuration(currentProject!.total) : "0h 0m",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (!hasAccounts) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "No accounts yet. Create one in Bank.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!hasAccounts) {
            // Send them to Bank to create an account
            context.push('/bank');
            return;
          }
          context.push('/pray');
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  Duration _computeTodayTotal(SessionState session) {
    final now = DateTime.now();
    var total = Duration.zero;

    for (final p in session.projects) {
      for (final s in p.sessions) {
        if (s.date.year == now.year && s.date.month == now.month && s.date.day == now.day) {
          total += s.duration;
        }
      }
    }

    return total;
  }

  Duration _computeWeekTotal(SessionState session) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Mon 00:00-ish
    var total = Duration.zero;

    for (final p in session.projects) {
      for (final s in p.sessions) {
        if (s.date.isAfter(startOfWeek) || _isSameDay(s.date, startOfWeek)) {
          total += s.duration;
        }
      }
    }

    return total;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
  }
}
