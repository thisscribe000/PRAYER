import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/pray_with_me_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Already used for projects/accounts
  await Hive.openBox('projectsBox');

  // NEW: persistent session run-state
  await Hive.openBox('sessionBox');

  runApp(const ProviderScope(child: PrayWithMeApp()));
}
