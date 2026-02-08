import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../domain/session_controller.dart';
import 'widgets/progress_ring.dart';

class PrayNowScreen extends ConsumerWidget {
  const PrayNowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);

    const totalSession = Duration(minutes: 60);
    final elapsed = session.elapsed;

    final elapsedSeconds = elapsed.inSeconds;
    final totalSeconds = totalSession.inSeconds;

    final progress = totalSeconds == 0
        ? 0.0
        : (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);

    final remaining = totalSession - elapsed;
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Pray With Me",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ✅ Timer Section
            Column(
              children: [
                Text(
                  "PRAYER SESSION",
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ Ring with ONLY elapsed centered inside
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ProgressRing(
                        progress: progress,
                        color: theme.colorScheme.primary,
                        backgroundColor: theme.dividerColor.withAlpha(77),
                        strokeWidth: 12.0,
                      ),

                      // Center: Elapsed + time (centered)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Elapsed",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withAlpha(153),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatDuration(elapsed),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ✅ Remaining OUTSIDE the circle (between ring and dropdown)
                const SizedBox(height: 18),
                Text(
                  "Remaining",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDurationMmSs(safeRemaining),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                // ✅ Move dropdown lower (more breathing room)
                const SizedBox(height: 28),

                // Account dropdown (taller)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Current Account",
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withAlpha(178),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ✅ Control Buttons (remove Break & Clock Out row)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        onPressed: () {
                          if (session.isRunning) {
                            controller.pause();
                          } else {
                            controller.start();
                          }
                        },
                        child: Text(
                          session.isRunning ? "Pause" : "Start",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: controller.end,
                        child: const Text(
                          "End Session",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (d.inHours > 0) {
      return "$hours:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }

  String _formatDurationMmSs(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
