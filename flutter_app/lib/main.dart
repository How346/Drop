import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const HyperDropApp(),
    ),
  );
  if (Platform.isAndroid) {
    await [Permission.nearbyWifiDevices, Permission.storage].request();
  }
  await state.init();
}

class HyperDropApp extends StatelessWidget {
  const HyperDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'HyperDrop',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      home: const AppShell(),
    );
  }
}
