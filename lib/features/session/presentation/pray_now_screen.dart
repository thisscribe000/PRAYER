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

    // Calculate progress for 60-minute session
    final totalSessionMinutes = 60;
    final elapsedMinutes = session.elapsed.inMinutes;
    final progress = elapsedMinutes / totalSessionMinutes;
    final remainingMinutes = totalSessionMinutes - elapsedMinutes;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Changed from background to surface
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
            // Project dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work_outline, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Current Project",
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withAlpha(178), // Changed from withOpacity
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Timer Section
            Column(
              children: [
                Text(
                  "PRAYER SESSION",
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withAlpha(153), // Changed from withOpacity
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Progress Ring with Time
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      ProgressRing(
                        progress: progress.clamp(0.0, 1.0),
                        color: theme.colorScheme.primary,
                        backgroundColor: theme.dividerColor.withAlpha(77), // Changed from withOpacity
                        strokeWidth: 12.0,
                      ),
                      
                      // Time Display
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Elapsed Section
                          Text(
                            "Elapsed",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withAlpha(153), // Changed from withOpacity
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(session.elapsed),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Remaining Section
                          Text(
                            "Remaining",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withAlpha(153), // Changed from withOpacity
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${remainingMinutes.toString().padLeft(2, '0')}:00",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface, // Changed from onBackground
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Control Buttons
            Column(
              children: [
                // Start/End Session Buttons
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
                
                const SizedBox(height: 16),
                
                // Secondary Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // Handle Break
                        },
                        icon: const Icon(Icons.free_breakfast_outlined, size: 20),
                        label: const Text("Break"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // Handle Clock Out
                        },
                        icon: const Icon(Icons.logout_outlined, size: 20),
                        label: const Text("Clock Out"),
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
}