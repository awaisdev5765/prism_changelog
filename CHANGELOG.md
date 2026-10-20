# Changelog

## 0.1.0

- Initial release.
- `ChangelogParser` — Keep-a-Changelog markdown → typed entries with numeric
  version comparison.
- `ChangelogView` — version cards with dates, titles, NEW badge, collapsible
  history, and custom bullet builders.
- `WhatsNewSheet.show` — auto-popup bottom sheet filtered by last-seen
  version, with pluggable persistence.
- Keep-a-Changelog `### Category` subsections parse and render as grouped
  headers (Added / Fixed / Changed / …).
- `ChangelogParser.fromAsset` — load CHANGELOG.md from the asset bundle.
- Localizable labels on `ChangelogStyle`: `badgeText`, `showOlderLabel`,
  `showFewerLabel`, plus a `categoryStyle` knob.
