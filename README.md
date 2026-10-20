# changelog_widget

In-app **"What's New"** screens and changelog views for Flutter — parses
Keep-a-Changelog markdown into beautiful version cards, tracks last-seen
versions, and needs zero configuration.

Part of the **Prism** package family.

## Features

- ✅ `ChangelogView` — version cards with date, title, bullets, and a NEW badge
- ✅ `WhatsNewSheet` — ready-made bottom sheet showing only what's new since
  the user's last visit
- ✅ Version tracking — persists the last-seen version (pluggable store)
- ✅ Parses real changelog files: `## [1.2.0] - 2026-01-15`, `## 1.2.0`,
  `### 1.2.0 (Hotfix)` — numeric version comparison included (`1.10 > 1.9`)
- ✅ Bullets keep their markdown (`**bold**`, links) — pair with
  [prism_markdown](https://pub.dev/packages/prism_markdown) via
  `bulletBuilder` for rich rendering
- ✅ Collapsible older versions
- ✅ Pure Flutter, all six platforms

## Installation

```yaml
dependencies:
  changelog_widget: ^0.1.0
```

## What's New sheet (auto-popup pattern)

After an app update, show users only what changed:

```dart
await WhatsNewSheet.show(
  context,
  changelog: myChangelogMarkdown, // your CHANGELOG.md as a string
  store: const SharedPrefsSeenStore(), // default
);
```

First launch: shows everything. After dismissing: next launch shows only
versions newer than the last-seen one.

## Full history view

```dart
ChangelogView(
  changelog: myChangelogMarkdown,
  highlightVersion: currentVersion, // NEW badge
  collapsible: true, // "Show older (4)" toggle
)
```

## Rich bullets with prism_markdown

```dart
ChangelogView(
  changelog: myChangelog,
  bulletBuilder: (bullet) => PrismMarkdown(bullet),
)
```

## The Prism package family

| Package | What it does |
| --- | --- |
| [prism_markdown](https://pub.dev/packages/prism_markdown) | Markdown widget with full CommonMark + GFM support |
| [prism_code_view](https://pub.dev/packages/prism_code_view) | Syntax-highlighted code viewer (Dart/JSON/YAML built in) |
| [prism_adaptive_scaffold](https://pub.dev/packages/prism_adaptive_scaffold) | Responsive scaffolds: bottom bar → rail → extended rail |
| [prism_adaptive_dialog](https://pub.dev/packages/prism_adaptive_dialog) | Dialogs that become bottom sheets on phones |
| [prism_state_views](https://pub.dev/packages/prism_state_views) | Empty, loading, error, and success states from one widget |
| [prism_master_detail](https://pub.dev/packages/prism_master_detail) | Adaptive master-detail layouts |
| [prism_banner](https://pub.dev/packages/prism_banner) | Dismissible announcement banners |
| [prism_search](https://pub.dev/packages/prism_search) | Adaptive search with suggestions |
| [prism_toast](https://pub.dev/packages/prism_toast) | Adaptive toast notifications |
| [prism_pagination](https://pub.dev/packages/prism_pagination) | Infinite-scroll lists with all states handled |
| [prism_form](https://pub.dev/packages/prism_form) | Declarative forms with sealed submit states |
| **changelog_widget** | In-app "What's New" screens and changelog views |

All pure Flutter, all six platforms, MIT licensed, built to work together.

## License

MIT — see [LICENSE](LICENSE).
