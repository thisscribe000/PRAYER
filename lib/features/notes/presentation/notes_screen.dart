import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Your palette
    const darkBg = Color(0xFF232426);
    const darkSurface = Color(0xFF353A3E);
    const lightBg = Color(0xFFEEEFF0);

    final bg = isDark ? darkBg : lightBg;
    final cardBg = isDark ? darkSurface : Colors.white;
    final outline = isDark ? Colors.white12 : Colors.black12;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final subtleText = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        title: const Text(
          'Notes',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: outline),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sticky_note_2_outlined, color: primaryText, size: 34),
                const SizedBox(height: 10),
                Text(
                  'Notes is coming soon',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You’ll be able to add notes per day and per account after you log prayer sessions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtleText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
