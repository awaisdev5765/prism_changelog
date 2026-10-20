/// In-app "What's New" screens and changelog views for Flutter.
///
/// Part of the Prism package family:
///
/// - [prism_markdown](https://pub.dev/packages/prism_markdown)
/// - [prism_code_view](https://pub.dev/packages/prism_code_view)
/// - [prism_adaptive_scaffold](https://pub.dev/packages/prism_adaptive_scaffold)
/// - [prism_adaptive_dialog](https://pub.dev/packages/prism_adaptive_dialog)
/// - [prism_state_views](https://pub.dev/packages/prism_state_views)
/// - [prism_master_detail](https://pub.dev/packages/prism_master_detail)
/// - [prism_banner](https://pub.dev/packages/prism_banner)
/// - [prism_search](https://pub.dev/packages/prism_search)
/// - [prism_toast](https://pub.dev/packages/prism_toast)
/// - [prism_pagination](https://pub.dev/packages/prism_pagination)
/// - [prism_form](https://pub.dev/packages/prism_form)
library;

export 'src/changelog_view.dart'
    show ChangelogStyle, ChangelogView, WhatsNewSheet;
export 'src/entry.dart' show ChangelogEntry, ChangelogParser;
export 'src/store.dart'
    show InMemorySeenStore, SeenVersionStore, SharedPrefsSeenStore;
