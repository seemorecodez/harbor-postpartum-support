import '../content/guide.dart';
import '../content/stories.dart';
import 'models.dart';

/// Public, non-personal metadata shown inside Harbor and checked against the
/// packaged release files. Nothing in this object is read from the local vault.
abstract final class HarborReleaseInfo {
  static const version = '0.1.0-alpha.17';
  static const buildNumber = 17;
  static const releaseStatus = 'Engineering alpha';
  static const dataSchemaVersion = HarborData.currentSchemaVersion;
  static const guideCatalog = guideCatalogVersion;
  static const storiesCatalog = storyCatalogVersion;
  static const guideStatus = guideReviewStatus;
  static const storiesStatus = pendingLivedExperienceReview;
  static const license = 'MIT License';
  static const copyright = 'Copyright (c) 2026 SeemoreCodez';

  static String get versionLabel => '$version (build $buildNumber)';

  static String get guideLabel =>
      '$guideCatalog · ${guideEntries.length} source-backed entries';

  static String get storiesLabel =>
      '$storiesCatalog · ${storyEntries.length} editorial drafts';
}
