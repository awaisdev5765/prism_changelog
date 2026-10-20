import 'package:flutter/material.dart';

import 'entry.dart';
import 'store.dart';

/// Visual configuration for [ChangelogView] and [WhatsNewSheet].
@immutable
class ChangelogStyle {
  /// Creates a style; unset fields fall back to the ambient [ThemeData].
  const ChangelogStyle({
    this.cardColor,
    this.versionStyle,
    this.dateStyle,
    this.bulletStyle,
    this.badgeColor,
    this.badgeTextStyle,
    this.spacing = 12,
    this.cardPadding = const EdgeInsets.all(16),
  });

  /// Card background; defaults to `surfaceContainerLow`.
  final Color? cardColor;

  /// Version number text style.
  final TextStyle? versionStyle;

  /// Date text style.
  final TextStyle? dateStyle;

  /// Bullet text style.
  final TextStyle? bulletStyle;

  /// "New" badge background color.
  final Color? badgeColor;

  /// "New" badge text style.
  final TextStyle? badgeTextStyle;

  /// Vertical gap between cards.
  final double spacing;

  /// Inner card padding.
  final EdgeInsetsGeometry cardPadding;
}

/// Renders parsed [ChangelogEntry]s as beautiful version cards.
///
/// Pass your raw changelog markdown, or pre-parsed entries. Each version
/// becomes a card with the version, optional date/title, and its bullets.
/// Bullets keep their raw markdown (bold, links), so pair with
/// `prism_markdown` for rich rendering via [bulletBuilder].
///
/// ```dart
/// ChangelogView(changelog: myChangelogMarkdown)
/// ```
class ChangelogView extends StatelessWidget {
  /// Creates a changelog view.
  const ChangelogView({
    super.key,
    this.changelog,
    this.entries,
    this.style,
    this.collapsible = true,
    this.initiallyExpandedCount = 3,
    this.bulletBuilder,
    this.highlightVersion,
  }) : assert(
         (changelog != null) != (entries != null),
         'Provide exactly one of changelog or entries.',
       );

  /// Raw Keep-a-Changelog markdown. Mutually exclusive with [entries].
  final String? changelog;

  /// Pre-parsed entries. Mutually exclusive with [changelog].
  final List<ChangelogEntry>? entries;

  /// Visual configuration.
  final ChangelogStyle? style;

  /// Whether versions beyond [initiallyExpandedCount] start collapsed
  /// behind a "Show older" toggle.
  final bool collapsible;

  /// Number of newest versions shown before collapsing.
  final int initiallyExpandedCount;

  /// Custom bullet renderer — receives the raw markdown bullet. Great fit:
  /// `(bullet) => PrismMarkdown(bullet)`.
  final Widget Function(String bullet)? bulletBuilder;

  /// Version string highlighted with a "New" badge (e.g. the current app
  /// version on a What's New screen).
  final String? highlightVersion;

  @override
  Widget build(BuildContext context) {
    final parsed = entries ?? ChangelogParser.parse(changelog!);
    final s = style ?? const ChangelogStyle();
    if (parsed.isEmpty) {
      return const SizedBox.shrink();
    }

    final ordered = [...parsed]..sort((a, b) => b.compareTo(a));
    final visibleCount = collapsible && ordered.length > initiallyExpandedCount
        ? initiallyExpandedCount
        : ordered.length;

    return _ExpandableList(
      ordered: ordered,
      visibleCount: visibleCount,
      style: s,
      bulletBuilder: bulletBuilder,
      highlightVersion: highlightVersion,
      collapsible: collapsible,
      totalCount: ordered.length,
    );
  }
}

class _ExpandableList extends StatefulWidget {
  const _ExpandableList({
    required this.ordered,
    required this.visibleCount,
    required this.style,
    required this.bulletBuilder,
    required this.highlightVersion,
    required this.collapsible,
    required this.totalCount,
  });

  final List<ChangelogEntry> ordered;
  final int visibleCount;
  final ChangelogStyle style;
  final Widget Function(String bullet)? bulletBuilder;
  final String? highlightVersion;
  final bool collapsible;
  final int totalCount;

  @override
  State<_ExpandableList> createState() => _ExpandableListState();
}

class _ExpandableListState extends State<_ExpandableList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final count = _expanded ? widget.ordered.length : widget.visibleCount;
    final theme = Theme.of(context);
    final s = widget.style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(bottom: s.spacing),
            child: _VersionCard(
              entry: widget.ordered[i],
              style: s,
              theme: theme,
              bulletBuilder: widget.bulletBuilder,
              isNew: widget.highlightVersion == widget.ordered[i].version,
            ),
          ),
        if (widget.collapsible && widget.totalCount > widget.visibleCount)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? 'Show fewer'
                    : 'Show older (${widget.totalCount - widget.visibleCount})',
              ),
            ),
          ),
      ],
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.entry,
    required this.style,
    required this.theme,
    required this.bulletBuilder,
    required this.isNew,
  });

  final ChangelogEntry entry;
  final ChangelogStyle style;
  final ThemeData theme;
  final Widget Function(String bullet)? bulletBuilder;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final color = style.cardColor ?? theme.colorScheme.surfaceContainerLow;
    final versionStyle =
        (style.versionStyle ??
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))
            .copyWith(color: theme.colorScheme.onSurface);
    final dateStyle = (style.dateStyle ?? const TextStyle(fontSize: 12.5))
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    final bulletStyle =
        (style.bulletStyle ?? const TextStyle(fontSize: 14, height: 1.4))
            .copyWith(color: theme.colorScheme.onSurface);

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: style.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('v${entry.version}', style: versionStyle),
                if (entry.title != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.title!,
                      style: dateStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (isNew) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          style.badgeColor ??
                          theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'NEW',
                      style:
                          style.badgeTextStyle ??
                          TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            if (entry.date != null) ...[
              const SizedBox(height: 2),
              Text(entry.date!, style: dateStyle),
            ],
            const SizedBox(height: 8),
            for (final bullet in entry.bullets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child:
                          bulletBuilder?.call(bullet) ??
                          Text(bullet, style: bulletStyle),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A ready-made "What's New" bottom sheet.
///
/// Shows only entries newer than [lastSeenVersion] (or all when null),
/// then records the newest visible version via [store] when dismissed.
///
/// ```dart
/// await WhatsNewSheet.show(
///   context,
///   changelog: myChangelog,
///   lastSeenVersion: await store.lastSeenVersion(),
///   onDismiss: (newestVersion) => store.markSeen(newestVersion),
/// );
/// ```
class WhatsNewSheet extends StatelessWidget {
  /// Creates the sheet content (usually via [show]).
  const WhatsNewSheet({
    super.key,
    this.changelog,
    this.entries,
    required this.sinceVersion,
    this.style,
    this.title = 'What\u2019s New',
    this.bulletBuilder,
  });

  /// Raw changelog markdown. Mutually exclusive with [entries].
  final String? changelog;

  /// Pre-parsed entries. Mutually exclusive with [changelog].
  final List<ChangelogEntry>? entries;

  /// Only entries strictly newer than this are shown; null shows all.
  final String? sinceVersion;

  /// Visual configuration.
  final ChangelogStyle? style;

  /// Sheet title.
  final String title;

  /// Custom bullet renderer (e.g. `prism_markdown`).
  final Widget Function(String bullet)? bulletBuilder;

  /// Shows the sheet and returns when dismissed. The newest version shown
  /// is reported through [onDismiss] so the caller can persist it.
  static Future<void> show(
    BuildContext context, {
    required String changelog,
    String? lastSeenVersion,
    ChangelogStyle? style,
    String title = 'What\u2019s New',
    Widget Function(String bullet)? bulletBuilder,
    Future<void> Function(String newestVersion)? onDismiss,
    SeenVersionStore store = const SharedPrefsSeenStore(),
    bool autoPersist = true,
  }) async {
    if (lastSeenVersion != null) {
      final seen = await store.lastSeenVersion();
      if (!context.mounted) return;
      lastSeenVersion = seen ?? lastSeenVersion;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: WhatsNewSheet(
          changelog: changelog,
          sinceVersion: lastSeenVersion,
          style: style,
          title: title,
          bulletBuilder: bulletBuilder,
        ),
      ),
    );
    final entries = ChangelogParser.parse(changelog);
    if (entries.isEmpty) return;
    final newest = entries.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    if (!context.mounted) return;
    if (autoPersist) {
      await store.markSeen(newest.version);
    } else {
      await onDismiss?.call(newest.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = entries ?? ChangelogParser.parse(changelog!);
    final visible = sinceVersion == null
        ? all
        : all
              .where((e) => e.compareTo(_parseVersion(sinceVersion!)) > 0)
              .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: visible.isEmpty
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    child: ChangelogView(
                      entries: visible,
                      style: style,
                      collapsible: false,
                      bulletBuilder: bulletBuilder,
                      highlightVersion: _newest(visible)?.version,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static ChangelogEntry _parseVersion(String version) =>
      ChangelogEntry(version: version, bullets: const []);

  static ChangelogEntry? _newest(List<ChangelogEntry> entries) {
    if (entries.isEmpty) return null;
    return entries.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
  }
}
