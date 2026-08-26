import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production logs do not reference authentication secrets', () {
    final RegExp logSink = RegExp(
      r'\b(?:debugPrint|print)\s*\('
      r'|System\.(?:out|err)\.print'
      r'|\b(?:logger|log)\s*\.\s*(?:trace|debug|info|warn|error)\s*\(',
      caseSensitive: false,
    );
    final RegExp secret = RegExp(
      r'\b(?:access[_\s-]*token|refresh[_\s-]*token|authorization'
      r'|password|verification[_\s-]*code|identity[_\s-]*token'
      r'|provider[_\s-]*token)\b',
      caseSensitive: false,
    );
    final List<String> findings = <String>[];

    for (final String rootPath in <String>['lib', 'backend/src/main']) {
      final Directory root = Directory(rootPath);
      for (final FileSystemEntity entity in root.listSync(recursive: true)) {
        if (entity is! File ||
            (!entity.path.endsWith('.dart') &&
                !entity.path.endsWith('.java'))) {
          continue;
        }
        final List<String> lines = entity.readAsLinesSync();
        for (int index = 0; index < lines.length; index += 1) {
          final int end = min(index + 3, lines.length);
          final String window = lines.sublist(index, end).join(' ');
          if (logSink.hasMatch(window) && secret.hasMatch(window)) {
            findings.add('${entity.path}:${index + 1}');
          }
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason: 'Authentication secrets must never be passed to log sinks.',
    );
  });
}
