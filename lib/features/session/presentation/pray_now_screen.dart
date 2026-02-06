import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/progress_ring.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../domain/session_controller.dart';

class PrayNowScreen extends ConsumerWidget {
  const PrayNowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pray With Me",
          style: TextStyle(fontSize: 14),
        ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            const Text(
              "PRAYER SESSION",
              style: TextStyle(fontSize: 12, letterSpacing: 1.2),
            ),

            const SizedBox(height: 8),

            /// 🔽 Project Dropdown
            DropdownButton<String>(
              value: session.selectedProjectId,
              isExpanded: true,
              underline: const SizedBox(),
              items: session.projects
                  .map(
                    (project) => DropdownMenuItem(
                      value: project.id,
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectProject(value);
                }
              },
            ),

            const SizedBox(height: 48),

            /// Circle Placeholder
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ProgressRing(
                    elapsed: session.elapsed,
                    maxDuration: const Duration(minutes: 60),
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: theme.dividerColor,
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Elapsed", style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(session.elapsed),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Remaining", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),


            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                      session.isRunning
                          ? "Pause"
                          : session.elapsed == Duration.zero
                              ? "Start"
                              : "Resume",
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      controller.end();
                    },
                    child: const Text("End Session"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
