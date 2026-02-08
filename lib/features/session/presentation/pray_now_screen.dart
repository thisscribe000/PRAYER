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

    // ✅ Corrected + clean
    final current = controller.currentProject;
    final selectedAccountName = current.name;
    final savedTotal = current.total;

    final liveTotal =
        savedTotal + (session.isRunning ? session.elapsed : Duration.zero);

    // TEMP test cycle (60 seconds)
    const cycle = Duration(seconds: 60);

    final elapsed = session.elapsed;
    final elapsedSeconds = elapsed.inSeconds;
    final cycleSeconds = cycle.inSeconds;

    final cycleIndex =
        cycleSeconds == 0 ? 0 : (elapsedSeconds ~/ cycleSeconds);

    final cycleElapsedSeconds =
        cycleSeconds == 0 ? 0 : (elapsedSeconds % cycleSeconds);

    final progress = cycleSeconds == 0
        ? 0.0
        : (cycleElapsedSeconds / cycleSeconds).clamp(0.0, 1.0);

    final targetRingColor = (cycleIndex % 2 == 0)
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    final dropdownDisabled = session.isRunning;

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
              final currentMode = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  currentMode == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light;
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: Builder(
                    key: ValueKey(targetRingColor.toARGB32()),
                    builder: (_) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ProgressRing(
                            progress: progress,
                            color: targetRingColor,
                            backgroundColor:
                                theme.dividerColor.withAlpha(77),
                            strokeWidth: 12.0,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Praying Now",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(153),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _formatDurationFlexible(elapsed),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: targetRingColor,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Total Time Prayed",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(153),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDurationHhMmSs(liveTotal),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1.0,
              ),
            ),

            const SizedBox(height: 22),

            InkWell(
              onTap: dropdownDisabled
                  ? null
                  : () => _openAccountPicker(
                      context, theme, session, controller),
              child: Opacity(
                opacity: dropdownDisabled ? 0.6 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
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
                                color: theme.colorScheme.onSurface
                                    .withAlpha(140),
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedAccountName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),

            if (dropdownDisabled) ...[
              const SizedBox(height: 10),
              Text(
                "Prayer already in progress",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],

            const SizedBox(height: 18),

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
                    onPressed:
                        (session.isRunning || session.elapsed > Duration.zero)
                            ? controller.end
                            : null,
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

  String _formatDurationHhMmSs(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hh:$mm:$ss";
  }
}
