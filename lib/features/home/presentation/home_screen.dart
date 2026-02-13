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
    final allTimeTotal = _computeAllTimeTotal(session);

    final latest = _computeLatestSessions(session, limit: 5);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Color references from you:
    // dark bg: #232426, dark surface: #353a3e, light bg: #eeeff0
    const darkBg = Color(0xFF232426);
    const darkSurface = Color(0xFF353A3E);
    const lightBg = Color(0xFFEEEFF0);

    final scaffoldBg = isDark ? darkBg : lightBg;
    final cardBg = isDark ? darkSurface : Colors.white;
    final subtleText = isDark ? Colors.white70 : Colors.black54;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final outline = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: scaffoldBg,
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO: Total Prayer Time
              _HeroTotalCard(
                backgroundColor: cardBg,
                outlineColor: outline,
                labelColor: subtleText,
                valueColor: primaryText,
                total: allTimeTotal,
                format: _formatDurationHms,
              ),
              const SizedBox(height: 12),

              // Quick actions row (Bank, Notes, Pray, More)
              _QuickActionsCard(
                backgroundColor: cardBg,
                outlineColor: outline,
                labelColor: subtleText,
                iconColor: primaryText,
                onBank: () => context.push('/bank'),
                onNotes: () => context.push('/notes'),
                onPray: () {
                  if (!hasAccounts) {
                    context.push('/bank');
                    return;
                  }
                  context.push('/pray');
                },
                onMore: () => context.push('/settings'),
              ),
              const SizedBox(height: 16),

              // Overview mini totals (Today / Week / Current Account) — compact, “financial dashboard” feel
              _MiniTotalsRow(
                backgroundColor: cardBg,
                outlineColor: outline,
                labelColor: subtleText,
                valueColor: primaryText,
                todayTotal: todayTotal,
                weekTotal: weekTotal,
                currentTotal: hasAccounts ? currentProject!.total : Duration.zero,
                hasAccounts: hasAccounts,
                formatShort: _formatDurationShort,
              ),
              const SizedBox(height: 18),

              // Latest header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/bank'),
                    child: const Text('see all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Latest list
              if (latest.isEmpty)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: outline),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    hasAccounts
                        ? 'No sessions yet. Start praying to see activity here.'
                        : 'No accounts yet. Create one in Bank.',
                    style: TextStyle(color: subtleText, fontSize: 12),
                  ),
                )
              else
                Column(
                  children: [
                    for (final item in latest) ...[
                      _LatestRowCard(
                        backgroundColor: cardBg,
                        outlineColor: outline,
                        titleColor: primaryText,
                        subtitleColor: subtleText,
                        title: item.projectName,
                        subtitle: _formatDateForSubtitle(item.date),
                        trailing: _formatDurationHms(item.duration),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
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

  Duration _computeAllTimeTotal(SessionState session) {
    var total = Duration.zero;
    for (final p in session.projects) {
      for (final s in p.sessions) {
        total += s.duration;
      }
    }
    return total;
  }

  List<_LatestItem> _computeLatestSessions(SessionState session, {int limit = 5}) {
    final items = <_LatestItem>[];

    for (final p in session.projects) {
      for (final s in p.sessions) {
        items.add(_LatestItem(
          projectName: p.name,
          date: s.date,
          duration: s.duration,
        ));
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    if (items.length <= limit) return items;
    return items.take(limit).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Old format kept (short “dashboard chips”)
  String _formatDurationShort(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
  }

  // New format for the hero + latest rows: HHH:MM:SS
  String _formatDurationHms(Duration d) {
    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String two(int n) => n.toString().padLeft(2, '0');
    return "$hours:${two(minutes)}:${two(seconds)}";
  }

  String _formatDateForSubtitle(DateTime d) {
    // Minimal, no intl dependency.
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = months[(d.month - 1).clamp(0, 11)];
    return "$m ${d.day}, ${d.year}";
  }
}

class _HeroTotalCard extends StatelessWidget {
  const _HeroTotalCard({
    required this.backgroundColor,
    required this.outlineColor,
    required this.labelColor,
    required this.valueColor,
    required this.total,
    required this.format,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color labelColor;
  final Color valueColor;
  final Duration total;
  final String Function(Duration) format;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outlineColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        children: [
          Text(
            'Total Prayer Time',
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            format(total),
            style: TextStyle(
              color: valueColor,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.backgroundColor,
    required this.outlineColor,
    required this.labelColor,
    required this.iconColor,
    required this.onBank,
    required this.onNotes,
    required this.onPray,
    required this.onMore,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color labelColor;
  final Color iconColor;

  final VoidCallback onBank;
  final VoidCallback onNotes;
  final VoidCallback onPray;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    Widget action({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor.withValues(alpha: 0.10)),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outlineColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          action(icon: Icons.account_balance_wallet_outlined, label: 'Bank', onTap: onBank),
          action(icon: Icons.sticky_note_2_outlined, label: 'Notes', onTap: onNotes),
          action(icon: Icons.favorite_outline, label: 'Pray with me', onTap: onPray),
          action(icon: Icons.more_horiz, label: 'More', onTap: onMore),
        ],
      ),
    );
  }
}

class _MiniTotalsRow extends StatelessWidget {
  const _MiniTotalsRow({
    required this.backgroundColor,
    required this.outlineColor,
    required this.labelColor,
    required this.valueColor,
    required this.todayTotal,
    required this.weekTotal,
    required this.currentTotal,
    required this.hasAccounts,
    required this.formatShort,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color labelColor;
  final Color valueColor;

  final Duration todayTotal;
  final Duration weekTotal;
  final Duration currentTotal;
  final bool hasAccounts;

  final String Function(Duration) formatShort;

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: outlineColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('Today', formatShort(todayTotal)),
        const SizedBox(width: 10),
        tile('This Week', formatShort(weekTotal)),
        const SizedBox(width: 10),
        tile('Current Account', hasAccounts ? formatShort(currentTotal) : '0h 0m'),
      ],
    );
  }
}

class _LatestRowCard extends StatelessWidget {
  const _LatestRowCard({
    required this.backgroundColor,
    required this.outlineColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color titleColor;
  final Color subtitleColor;

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outlineColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: titleColor.withValues(alpha: 0.12)),
              color: titleColor.withValues(alpha: 0.08),
            ),
            child: Icon(Icons.person_outline, size: 18, color: titleColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestItem {
  _LatestItem({
    required this.projectName,
    required this.date,
    required this.duration,
  });

  final String projectName;
  final DateTime date;
  final Duration duration;
}
