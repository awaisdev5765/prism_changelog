import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetBundle, ImmutableBuffer;
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_changelog/prism_changelog.dart';
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

  group('Categorized sections', () {
    const categorized = '''
## [2.0.0] - 2026-02-01
### Added
- Dark mode
- Keyboard shortcuts

### Fixed
- Crash on cold start

## [1.0.0] - 2025-12-01
- Initial release
''';

    test('parser groups bullets under subsections', () {
      final entries = ChangelogParser.parse(categorized);
      expect(entries.first.isCategorized, isTrue);
      expect(entries.first.sections['Added'], [
        'Dark mode',
        'Keyboard shortcuts',
      ]);
      expect(entries.first.sections['Fixed'], ['Crash on cold start']);
      // Flat list stays in document order for simple consumers.
      expect(entries.first.bullets, [
        'Dark mode',
        'Keyboard shortcuts',
        'Crash on cold start',
      ]);
      expect(entries.last.isCategorized, isFalse);
    });

    testWidgets('cards render category headers', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChangelogView(changelog: categorized, collapsible: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Added'), findsOneWidget);
      expect(find.text('Fixed'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
    });

    testWidgets('labels are customizable', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangelogView(
              changelog: _sample,
              highlightVersion: '2.0.0',
              style: const ChangelogStyle(badgeText: 'JUUZ'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('JUUZ'), findsOneWidget);
    });
  });

  group('Asset loading', () {
    test('fromAsset parses a bundle-provided changelog', () async {
      const source = '## [1.2.0]\n- From asset';
      final bundle = _FakeBundle({'CHANGELOG.md': source});
      final entries = await ChangelogParser.fromAsset(
        'CHANGELOG.md',
        bundle: bundle,
      );
      expect(entries.single.version, '1.2.0');
      expect(entries.single.bullets, ['From asset']);
    });
  });
}

class _FakeBundle implements AssetBundle {
  _FakeBundle(this._strings);

  final Map<String, String> _strings;

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      _strings[key]!;

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<ImmutableBuffer> loadBuffer(String key) => throw UnimplementedError();

  @override
  void clear() {}

  @override
  void evict(String key) {}

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) => parser(_strings[key]!);

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) async => parser(ByteData(0));
}
