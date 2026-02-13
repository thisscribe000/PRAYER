import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/domain/session_controller.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

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

    final todayTotal = _computeTodayTotal(session);
    final weekTotal = _computeWeekTotal(session);
    final allTimeTotal = _computeAllTimeTotal(session);

    final streak = _computeStreakStats(session);
    final topProjects = _topProjectsByTotal(session, limit: 6);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: scaffoldBg,
        elevation: 0,
        title: const Text(
          'Insights',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroTotalCard(
                backgroundColor: cardBg,
                outlineColor: outline,
                labelColor: subtleText,
                valueColor: primaryText,
                total: allTimeTotal,
                format: _formatDurationHms,
                title: 'All-time Prayer',
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      backgroundColor: cardBg,
                      outlineColor: outline,
                      labelColor: subtleText,
                      valueColor: primaryText,
                      label: 'Today',
                      value: _formatDurationShort(todayTotal),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      backgroundColor: cardBg,
                      outlineColor: outline,
                      labelColor: subtleText,
                      valueColor: primaryText,
                      label: 'This Week',
                      value: _formatDurationShort(weekTotal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _StreakCard(
                backgroundColor: cardBg,
                outlineColor: outline,
                labelColor: subtleText,
                valueColor: primaryText,
                currentStreakDays: streak.currentStreakDays,
                longestStreakDays: streak.longestStreakDays,
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Accounts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                  Text(
                    'by total time',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subtleText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (session.projects.isEmpty)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: outline),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'No accounts yet. Create one in Bank to see insights.',
                    style: TextStyle(color: subtleText, fontSize: 12),
                  ),
                )
              else
                Column(
                  children: [
                    for (final p in topProjects) ...[
                      _AccountStatRow(
                        backgroundColor: cardBg,
                        outlineColor: outline,
                        titleColor: primaryText,
                        subtitleColor: subtleText,
                        title: p.name,
                        subtitle: _lastPrayedSubtitle(p.sessions),
                        trailing: _formatDurationHms(p.total),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),

              const SizedBox(height: 8),

              _ComingSoonCard(
                backgroundColor: cardBg,
                outlineColor: outline,
                titleColor: primaryText,
                subtitleColor: subtleText,
                title: 'Schedule & Projection',
                subtitle:
                    'Next: Ahead/Behind schedule, projected finish date, and completion milestone.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------- Totals ---------

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
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
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

  // --------- Streaks ---------

  _StreakStats _computeStreakStats(SessionState session) {
    final prayedDays = <DateTime>{};

    for (final p in session.projects) {
      for (final s in p.sessions) {
        prayedDays.add(_dayKey(s.date));
      }
    }

    if (prayedDays.isEmpty) {
      return const _StreakStats(currentStreakDays: 0, longestStreakDays: 0);
    }

    final sorted = prayedDays.toList()..sort((a, b) => b.compareTo(a)); // newest first

    // Current streak ends today.
    final today = _dayKey(DateTime.now());
    var current = 0;

    if (prayedDays.contains(today)) {
      var cursor = today;
      while (prayedDays.contains(cursor)) {
        current++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    // Longest streak across all prayed days.
    var longest = 1;
    var run = 1;

    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      final diff = a.difference(b).inDays;

      if (diff == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    return _StreakStats(currentStreakDays: current, longestStreakDays: longest);
  }

  // --------- Lists ---------

  List<dynamic> _topProjectsByTotal(SessionState session, {int limit = 6}) {
    final list = [...session.projects];
    list.sort((a, b) => b.total.compareTo(a.total));
    if (list.length <= limit) return list;
    return list.take(limit).toList();
  }

  // --------- Helpers ---------

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDurationShort(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
  }

  String _formatDurationHms(Duration d) {
    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String two(int n) => n.toString().padLeft(2, '0');
    return "$hours:${two(minutes)}:${two(seconds)}";
  }

  String _lastPrayedSubtitle(List<dynamic> sessions) {
    if (sessions.isEmpty) return 'No activity yet';

    sessions.sort((a, b) => b.date.compareTo(a.date));
    final d = sessions.first.date as DateTime;

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
    return "Last prayed: $m ${d.day}, ${d.year}";
  }
}

// ---------------- UI Pieces ----------------

class _HeroTotalCard extends StatelessWidget {
  const _HeroTotalCard({
    required this.backgroundColor,
    required this.outlineColor,
    required this.labelColor,
    required this.valueColor,
    required this.total,
    required this.format,
    required this.title,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color labelColor;
  final Color valueColor;
  final Duration total;
  final String Function(Duration) format;
  final String title;

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
            title,
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

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.backgroundColor,
    required this.outlineColor,
    required this.labelColor,
    required this.valueColor,
    required this.label,
    required this.value,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color labelColor;
  final Color valueColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.backgroundColor,
    required this.outlineColor,
    required this.labelColor,
    required this.valueColor,
    required this.currentStreakDays,
    required this.longestStreakDays,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color labelColor;
  final Color valueColor;
  final int currentStreakDays;
  final int longestStreakDays;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, String value) {
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
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
        pill('Current Streak', "${currentStreakDays}d"),
        const SizedBox(width: 10),
        pill('Longest Streak', "${longestStreakDays}d"),
      ],
    );
  }
}

class _AccountStatRow extends StatelessWidget {
  const _AccountStatRow({
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
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: titleColor,
            ),
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
                    fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.backgroundColor,
    required this.outlineColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.title,
    required this.subtitle,
  });

  final Color backgroundColor;
  final Color outlineColor;
  final Color titleColor;
  final Color subtitleColor;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outlineColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakStats {
  const _StreakStats({
    required this.currentStreakDays,
    required this.longestStreakDays,
  });

  final int currentStreakDays;
  final int longestStreakDays;
}
