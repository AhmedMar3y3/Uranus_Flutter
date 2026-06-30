import 'package:flutter/material.dart';

import 'src/app/app_dependencies.dart';
import 'src/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDependencies.notificationService.initialize();
  runApp(const UranusApp());
}
