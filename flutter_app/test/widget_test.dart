import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyperdrop/theme.dart';

void main() {
  testWidgets('theme builds for both brightnesses', (tester) async {
    expect(buildTheme(Brightness.dark).brightness, Brightness.dark);
    expect(buildTheme(Brightness.light).brightness, Brightness.light);
  });
}
