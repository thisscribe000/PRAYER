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

    final selectedAccountName = controller.currentProject.name;

    // Total prayed time for selected project (sum of saved sessions)
    final totalTimePrayed = controller.currentProject.total;

    // ✅ Ring loops every 60 minutes
    const cycle = Duration(seconds: 60); // TEMP test cycle

    final elapsed = session.elapsed;
    final elapsedSeconds = elapsed.inSeconds;
    final cycleSeconds = cycle.inSeconds;

    // which cycle are we currently in? (0,1,2,...)
    final cycleIndex = cycleSeconds == 0 ? 0 : (elapsedSeconds ~/ cycleSeconds);

    // progress inside the current cycle (0..cycleSeconds)
    final cycleElapsedSeconds =
        cycleSeconds == 0 ? 0 : (elapsedSeconds % cycleSeconds);

    final progress = cycleSeconds == 0
        ? 0.0
        : (cycleElapsedSeconds / cycleSeconds).clamp(0.0, 1.0);

    // ✅ Alternate ring color each cycle
    final ringColor =
        (cycleIndex % 2 == 0) ? theme.colorScheme.primary : theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Pray With Me",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header = selected account name
            Text(
              selectedAccountName,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 18),

            // Ring
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ProgressRing(
                      progress: progress,
                      color: ringColor,
                      backgroundColor: theme.dividerColor.withAlpha(77),
                      strokeWidth: 12.0,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Praying Now",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha(153),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          // keep current format (shows hours only when needed)
                          _formatDurationFlexible(elapsed),
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: ringColor,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Total time prayed for selected project
            Text(
              "Total Time Prayed",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(153),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              // ✅ Always HH:MM:SS even when hours = 00
              _formatDurationHhMmSs(totalTimePrayed),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 22),

            // Dropdown: square edges + two-line + selectable
            InkWell(
              onTap: () => _openAccountPicker(context, theme, session, controller),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Account",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withAlpha(140),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedAccountName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Buttons: pill
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
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
                        fontSize: 15,
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
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: controller.end,
                    child: const Text(
                      "End Session",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  void _openAccountPicker(
    BuildContext context,
    ThemeData theme,
    SessionState session,
    SessionController controller,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: session.projects.length,
            separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
            itemBuilder: (_, i) {
              final p = session.projects[i];
              final isSelected = p.id == session.selectedProjectId;

              return ListTile(
                title: Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () {
                  controller.selectProject(p.id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      },
    );
  }

  // Shows MM:SS, but switches to HH:MM:SS once hours > 0
  String _formatDurationFlexible(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return "$hh:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  // Always HH:MM:SS (even when hours = 00)
  String _formatDurationHhMmSs(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hh:$mm:$ss";
  }
}
