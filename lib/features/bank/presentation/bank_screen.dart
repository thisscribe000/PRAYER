import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_detail_screen.dart';
import '../../session/domain/session_controller.dart';

class BankScreen extends ConsumerWidget {
  const BankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prayer Bank',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ✅ New Project button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final controller = ref.read(sessionProvider.notifier);

                    final name = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        String tempName = "";

                        return AlertDialog(
                          title: const Text("New Project"),
                          content: TextField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: "Enter project name",
                            ),
                            onChanged: (value) => tempName = value,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, tempName),
                              child: const Text("Create"),
                            ),
                          ],
                        );
                      },
                    );

                    if (name != null && name.trim().isNotEmpty) {
                      controller.createProject(name.trim());
                    }
                  },
                  child: const Text("+ New Project"),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: session.projects.isEmpty
                    ? const Center(child: Text('No projects yet.'))
                    : ListView.separated(
                        itemCount: session.projects.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final project = session.projects[index];
                          final isSelected =
                              project.id == session.selectedProjectId;

                          return Card(
                            child: ListTile(
                              title: Text(project.name),
                              subtitle:
                                  Text('Total: ${_formatDuration(project.total)}'),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle)
                                  : const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProjectDetailScreen(projectId: project.id),
                                  ),
                                );

                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }
}
