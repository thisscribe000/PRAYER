import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pray With Me',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track your prayer hours. Pray with others. Stay consistent.',
            style: TextStyle(fontSize: 14, height: 1.3),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Today', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('0h 0m prayed'),
                  SizedBox(height: 6),
                  Text('Weekly total: 0h 0m'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Start a prayer session',
            onPressed: () => context.push('/session'),
          ),
        ],
      ),
    );
  }
}
