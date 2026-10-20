import 'package:flutter/material.dart';
import 'package:changelog_widget/changelog_widget.dart';

/// Demo app for changelog_widget.
void main() => runApp(const DemoApp());

const _changelog = '''
## [2.0.0] - 2026-02-01
- **Dark mode** everywhere
- Faster sync engine
- New adaptive widgets

## [1.1.0] (Hotfix) - 2026-01-05
- Crash fix on cold start

## [1.0.0] - 2025-12-01
- Initial release
''';

/// Root widget demonstrating the What's New sheet and full history.
class DemoApp extends StatelessWidget {
  /// Creates the demo.
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('changelog_widget demo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton(
              onPressed: () =>
                  WhatsNewSheet.show(context, changelog: _changelog),
              child: const Text('Show What\u2019s New'),
            ),
            const SizedBox(height: 16),
            ChangelogView(changelog: _changelog, highlightVersion: '2.0.0'),
          ],
        ),
      ),
    );
  }
}
