import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// A semantic changelog entry: one release version and its change bullets.
@immutable
class ChangelogEntry {
  /// Creates an entry.
  const ChangelogEntry({
    required this.version,
    required this.bullets,
    this.date,
    this.title,
    this.sections = const {},
  });

  /// Release version string, e.g. `1.2.0`.
  final String version;

  /// Optional release date string, e.g. `2026-01-15`.
  final String? date;

  /// Optional release title rendered next to the version.
  final String? title;

  /// Change bullets for this release, in document order.
  final List<String> bullets;

  /// Keep-a-Changelog subsections (`### Added`, `### Fixed`, …) mapped to
  /// their bullets. Empty when the changelog has no subsections.
  final Map<String, List<String>> sections;

  /// True when this entry uses named subsections instead of flat bullets.
  bool get isCategorized => sections.isNotEmpty;

  /// Parses [version] into comparable numeric segments; non-numeric
  /// segments (e.g. `beta`) compare as 0.
  List<int> get versionParts {
    final parts = <int>[];
    for (final segment in version.split('.')) {
      final digits = RegExp(r'^\d+').firstMatch(segment);
      parts.add(digits == null ? 0 : int.parse(digits.group(0)!));
    }
    return parts;
  }

  /// Three-way comparison against [other]: negative when this version is
  /// older, zero when equal, positive when newer.
  int compareTo(ChangelogEntry other) {
    final a = versionParts;
    final b = other.versionParts;
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }
    return 0;
  }
}

/// Parses Keep-a-Changelog-style markdown into [ChangelogEntry]s.
///
/// Recognized version header forms:
/// - `## [1.2.0] - 2026-01-15`
/// - `## 1.2.0`
/// - `### 1.2.0 (Hotfix)`
///
/// Everything else becomes a bullet of the current version. Bullet lines
/// starting with `- `, `* `, or `+ ` keep their markdown intact (bold,
/// links, etc.) so renderers like `prism_markdown` can style them.
///
/// ```dart
/// const changelog = '''
/// ## [1.2.0] - 2026-01-15
/// - Dark mode support
/// - Faster sync engine
///
/// ## [1.1.0] - 2025-12-01
/// - Initial public release
/// ''';
/// final entries = ChangelogParser.parse(changelog);
/// ```
abstract final class ChangelogParser {
  /// Parses [source] into entries, newest first.
  static List<ChangelogEntry> parse(String source) {
    final entries = <ChangelogEntry>[];
    ChangelogEntry? current;
    String? currentSection;

    for (final rawLine in source.split('\n')) {
      final line = rawLine.trimRight();
      final header = _versionHeader(line);
      if (header != null) {
        current = ChangelogEntry(
          version: header.version,
          date: header.date,
          title: header.title,
          bullets: [],
          sections: {},
        );
        entries.add(current);
        currentSection = null;
        continue;
      }
      if (current == null) continue;

      final subSection = _sectionHeader(line);
      if (subSection != null) {
        currentSection = subSection;
        current.sections.putIfAbsent(subSection, () => []);
        continue;
      }

      final bullet = _bullet(line);
      if (bullet == null) continue;
      if (currentSection != null) {
        current.sections[currentSection]!.add(bullet);
      }
      current.bullets.add(bullet);
    }
    return entries;
  }

  /// Convenience: loads and parses [assetPath] from [bundle] (defaults to
  /// the ambient asset bundle).
  static Future<List<ChangelogEntry>> fromAsset(
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final source = await (bundle ?? rootBundle).loadString(assetPath);
    return parse(source);
  }

  static _HeaderMatch? _versionHeader(String line) {
    final match = RegExp(
      r'^#{2,3}\s+(?:\[)?([^\]\s]+)\]?\s*(.*)$',
    ).firstMatch(line);
    if (match == null) return null;
    final version = match.group(1)!;
    final rest = match.group(2)!.trim();
    if (!RegExp(r'^\d').hasMatch(version)) return null;

    String? date;
    String? title;
    // A trailing ISO date may follow a title: "(Hotfix) - 2026-01-05".
    final trailingDate = RegExp(
      r'[-–—]\s*(\d{4}-\d{2}-\d{2})$',
    ).firstMatch(rest);
    if (trailingDate != null) {
      date = trailingDate.group(1);
    }
    final titleRaw = trailingDate == null
        ? rest
        : rest.substring(0, trailingDate.start).trim();
    if (titleRaw.isNotEmpty) {
      title = titleRaw.replaceFirst(RegExp(r'^[-–—]\s*'), '').trim();
      if (title.isEmpty) title = null;
    }
    return _HeaderMatch(version: version, date: date, title: title);
  }

  /// Recognized `### Category` subsection headers.
  static String? _sectionHeader(String line) {
    final match = RegExp(r'^###\s+(.+)$').firstMatch(line.trim());
    if (match == null) return null;
    final label = match.group(1)!.trim();
    // Avoid treating a date-only line as a section.
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(label)) return null;
    return label;
  }

  static String? _bullet(String line) {
    final match = RegExp(r'^[-*+]\s+(.+)$').firstMatch(line.trim());
    return match?.group(1);
  }
}

class _HeaderMatch {
  const _HeaderMatch({required this.version, this.date, this.title});

  final String version;
  final String? date;
  final String? title;
}
