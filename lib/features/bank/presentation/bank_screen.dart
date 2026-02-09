import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_detail_screen.dart';
import '../../session/domain/session_controller.dart';

class BankScreen extends ConsumerStatefulWidget {
  const BankScreen({super.key});

  @override
  ConsumerState<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends ConsumerState<BankScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  BankSort _sort = BankSort.newestFirst;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _tabTitle {
    switch (_tabController.index) {
      case 0:
        return 'Projects';
      case 1:
        return 'Ongoing';
      case 2:
        return 'Completed';
      default:
        return 'Prayer Bank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _tabTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          actions: [
            // Sort
            PopupMenuButton<BankSort>(
              tooltip: 'Sort',
              initialValue: _sort,
              onSelected: (value) => setState(() => _sort = value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: BankSort.newestFirst,
                  child: Text('Newest first'),
                ),
                PopupMenuItem(
                  value: BankSort.oldestFirst,
                  child: Text('Oldest first'),
                ),
                PopupMenuItem(
                  value: BankSort.nameAZ,
                  child: Text('Name A–Z'),
                ),
                PopupMenuItem(
                  value: BankSort.totalHighLow,
                  child: Text('Total high → low'),
                ),
              ],
              icon: const Icon(Icons.tune_rounded),
            ),
            const SizedBox(width: 4),

            // Add (keeps your exact createProject logic)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.tonal(
                onPressed: () => _createAccount(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Add'),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: scheme.onPrimaryContainer,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'Projects'),
                    Tab(text: 'Ongoing'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AccountsList(
                projects: session.projects,
                selectedProjectId: session.selectedProjectId,
                sort: _sort,
                onOpen: (id) => _openProject(context, id),
              ),
              _AccountsList(
                projects: session.projects
                    .where((p) => p.total > Duration.zero)
                    .toList(),
                selectedProjectId: session.selectedProjectId,
                sort: _sort,
                onOpen: (id) => _openProject(context, id),
              ),
              _AccountsList(
                projects: session.projects
                    .where((p) => p.total == Duration.zero)
                    .toList(),
                selectedProjectId: session.selectedProjectId,
                sort: _sort,
                onOpen: (id) => _openProject(context, id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAccount(BuildContext context) async {
    final controller = ref.read(sessionProvider.notifier);

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempName = "";

        return AlertDialog(
          title: const Text("New Account"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Enter account name",
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
  }

  void _openProject(BuildContext context, String projectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: projectId),
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  final List<dynamic> projects; // keep flexible (no model edits)
  final String? selectedProjectId;
  final BankSort sort;
  final void Function(String projectId) onOpen;

  const _AccountsList({
    required this.projects,
    required this.selectedProjectId,
    required this.sort,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (projects.isEmpty) {
      return const Center(child: Text('No accounts yet.'));
    }

    final items = List<dynamic>.from(projects);

    // Apply sort (UI only)
    items.sort((a, b) {
      switch (sort) {
        case BankSort.newestFirst:
          return _createdAt(b).compareTo(_createdAt(a));
        case BankSort.oldestFirst:
          return _createdAt(a).compareTo(_createdAt(b));
        case BankSort.nameAZ:
          return _safeName(a).toLowerCase().compareTo(_safeName(b).toLowerCase());
        case BankSort.totalHighLow:
          final tb = _safeTotal(b).inSeconds;
          final ta = _safeTotal(a).inSeconds;
          return tb.compareTo(ta);
      }
    });

    // Group by created date (fallback to single "Accounts" section if missing)
    final groups = <String, List<dynamic>>{};
    for (final p in items) {
      final dt = _createdAtNullable(p);
      final key = dt == null ? 'Accounts' : _formatSectionDate(dt);
      groups.putIfAbsent(key, () => []).add(p);
    }

    final sectionKeys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: sectionKeys.length,
      itemBuilder: (context, sectionIndex) {
        final header = sectionKeys[sectionIndex];
        final sectionItems = groups[header] ?? const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionIndex == 0) const SizedBox(height: 4) else const SizedBox(height: 18),

            Text(
              header,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),

            ...List.generate(sectionItems.length, (i) {
              final project = sectionItems[i];
              final id = (project as dynamic).id as String;
              final name = _safeName(project);
              final total = _safeTotal(project);
              final created = _createdAtNullable(project);

              final isSelected = id == selectedProjectId;

              return Padding(
                padding: EdgeInsets.only(bottom: i == sectionItems.length - 1 ? 0 : 10),
                child: _AccountCard(
                  name: name,
                  total: total,
                  createdAt: created,
                  isSelected: isSelected,
                  onTap: () => onOpen(id),
                ),
              );
            }),

            if (sectionIndex == sectionKeys.length - 1) const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  static String _safeName(dynamic p) {
    try {
      return (p as dynamic).name as String;
    } catch (_) {
      return 'Account';
    }
  }

  static Duration _safeTotal(dynamic p) {
    try {
      return (p as dynamic).total as Duration;
    } catch (_) {
      return Duration.zero;
    }
  }

  // Used for sorting even if null (null becomes epoch)
  static DateTime _createdAt(dynamic p) {
    return _createdAtNullable(p) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _createdAtNullable(dynamic p) {
    try {
      final dynamic v = (p as dynamic).createdAt;
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (_) {}

    // Common alternatives (no crash if absent)
    try {
      final dynamic v = (p as dynamic).createdAtMillis;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (_) {}

    try {
      final dynamic v = (p as dynamic).createdAtEpoch;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (_) {}

    return null;
  }

  static String _formatSectionDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const weekdays = [
      'Mon','Tue','Wed','Thu','Fri','Sat','Sun'
    ];
    final w = weekdays[(dt.weekday - 1).clamp(0, 6)];
    final m = months[(dt.month - 1).clamp(0, 11)];
    return '${dt.day} $m, $w';
  }
}

class _AccountCard extends StatelessWidget {
  final String name;
  final Duration total;
  final DateTime? createdAt;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountCard({
    required this.name,
    required this.total,
    required this.createdAt,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt == null
                          ? 'Created date'
                          : _formatCreatedLine(createdAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                    size: 20,
                    color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCreatedLine(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final m = months[(dt.month - 1).clamp(0, 11)];
    return 'Created ${dt.day} $m ${dt.year}';
  }

  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }
}

enum BankSort {
  newestFirst,
  oldestFirst,
  nameAZ,
  totalHighLow,
}
