import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/domain/session_controller.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    final project = session.projects.firstWhere(
      (p) => p.id == projectId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: session.projects.length <= 1
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text("Delete Project"),
                          content: const Text(
                            "Are you sure you want to delete this project?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        );
                      },
                    );

                    if (!context.mounted) return;

                    if (confirm == true) {
                      ref
                          .read(sessionProvider.notifier)
                          .deleteProject(project.id);
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              "Total: ${_formatDuration(project.total)}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Sessions",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: project.sessions.isEmpty
                  ? const Center(child: Text("No sessions yet"))
                  : ListView.builder(
                      itemCount: project.sessions.length,
                      itemBuilder: (context, index) {
                        final reversed = project.sessions.reversed.toList();
                        final sessionItem = reversed[index];

                        return Card(
                          child: ListTile(
                            title: Text(
                              _formatDuration(sessionItem.duration),
                            ),
                            subtitle: Text(
                              _formatDate(sessionItem.date),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) return "${hours}h ${minutes}m";
    if (minutes > 0) return "${minutes}m ${seconds}s";
    return "${seconds}s";
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }
}
