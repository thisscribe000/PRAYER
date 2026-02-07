import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/pray_with_me_app.dart'; // keep your real import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('projectsBox');

  runApp(const ProviderScope(child: PrayWithMeApp()));
}
