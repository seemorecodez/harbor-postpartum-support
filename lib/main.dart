import 'package:flutter/material.dart';

import 'app.dart';
import 'core/controller.dart';
import 'core/vault.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = HarborController(HarborVault());
  await controller.initialize();
  runApp(HarborApp(controller: controller));
}
