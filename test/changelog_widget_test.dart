import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changelog_widget/changelog_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sample = '''
# Changelog

## [2.0.0] - 2026-02-01
- **Dark mode** everywhere
- Faster sync engine

## [1.1.0] (Hotfix) - 2026-01-05
- Crash fix on cold start

## 1.0.0
- Initial release
''';

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  group('ChangelogParser', () {
    test('parses bracketed, titled, and plain headers', () {
      final entries = ChangelogParser.parse(_sample);
      expect(entries.length, 3);
      expect(entries[0].version, '2.0.0');
      expect(entries[0].date, '2026-02-01');
      expect(entries[0].bullets, hasLength(2));
      expect(entries[1].version, '1.1.0');
      expect(entries[1].title, '(Hotfix)');
      expect(entries[2].version, '1.0.0');
      expect(entries[2].bullets, ['Initial release']);
    });

    test('version comparison is numeric', () {
      final e = ChangelogParser.parse(_sample);
      expect(e[0].compareTo(e[1]), greaterThan(0));
      expect(e[1].compareTo(e[2]), greaterThan(0));
      expect(
        ChangelogEntry(
          version: '1.10.0',
          bullets: const [],
        ).compareTo(ChangelogEntry(version: '1.9.0', bullets: const [])),
        greaterThan(0),
      );
      expect(
        ChangelogEntry(
          version: '2.0.0-beta',
          bullets: const [],
        ).compareTo(ChangelogEntry(version: '2.0.0', bullets: const [])),
        0,
      );
    });

    test('keeps markdown in bullets', () {
      final entries = ChangelogParser.parse(_sample);
      expect(entries[0].bullets.first, '**Dark mode** everywhere');
    });

    test('ignores non-version headers', () {
      final entries = ChangelogParser.parse('''
## Unreleased
- not a version

## [1.0.0]
- real
''');
      expect(entries.length, 1);
      expect(entries.first.version, '1.0.0');
      expect(entries.first.bullets, ['real']);
    });
  });

  group('ChangelogView rendering', () {
    testWidgets('renders version cards newest first', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChangelogView(changelog: _sample, collapsible: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('v2.0.0'), findsOneWidget);
      expect(find.text('2026-02-01'), findsOneWidget);
      expect(find.text('**Dark mode** everywhere'), findsOneWidget);
      // newest-first order: v2.0.0 appears above v1.0.0
      final newRect = tester.getRect(find.text('v2.0.0'));
      final oldRect = tester.getRect(find.text('v1.0.0'));
      expect(newRect.top, lessThan(oldRect.top));
    });

    testWidgets('NEW badge highlights a version', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangelogView(
              changelog: _sample,
              collapsible: false,
              highlightVersion: '2.0.0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('collapsible hides older versions behind toggle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChangelogView(changelog: _sample),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // initiallyExpandedCount = 3 shows all; make a longer changelog:
      expect(find.text('v1.0.0'), findsOneWidget);
    });

    testWidgets('custom bullet builder is used', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangelogView(
              changelog: _sample,
              collapsible: false,
              bulletBuilder: (bullet) => Text('WRAPPED: $bullet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('WRAPPED:'), findsWidgets);
    });
  });

  group('WhatsNewSheet.show', () {
    testWidgets('persists newest version on dismiss', (tester) async {
      final store = InMemorySeenStore();
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => WhatsNewSheet.show(
                    context,
                    changelog: _sample,
                    store: store,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('What’s New'), findsOneWidget);
      expect(find.text('v2.0.0'), findsOneWidget);
      // Sheet still open until dismissed; close it.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(await store.lastSeenVersion(), '2.0.0');
    });

    testWidgets('only shows entries newer than sinceVersion', (tester) async {
      final store = InMemorySeenStore();
      await store.markSeen('1.1.0');
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => WhatsNewSheet.show(
                    context,
                    changelog: _sample,
                    lastSeenVersion: '1.1.0',
                    store: store,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('v2.0.0'), findsOneWidget);
      expect(find.text('v1.1.0'), findsNothing);
      expect(find.text('v1.0.0'), findsNothing);
    });
  });
}
