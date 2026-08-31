import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/content/guide.dart';
import 'package:harbor_app/content/stories.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/release_info.dart';

void main() {
  test('in-app release identity matches every packaged web identity', () async {
    final pubspec = await File('pubspec.yaml').readAsString();
    final bootstrap = await File('web/flutter_bootstrap.js').readAsString();
    final serviceWorker = await File('web/harbor_service_worker.js')
        .readAsString();
    final releaseFinalizer = await File('tool/finalize_web_release.dart')
        .readAsString();

    expect(
      pubspec,
      contains(
        'version: ${HarborReleaseInfo.version}+'
        '${HarborReleaseInfo.buildNumber}',
      ),
    );
    expect(
      bootstrap,
      contains('HARBOR_RELEASE = "${HarborReleaseInfo.version}"'),
    );
    expect(
      serviceWorker,
      contains('harbor-shell-${HarborReleaseInfo.version}'),
    );
    expect(
      releaseFinalizer,
      contains("'url': './flutter_bootstrap.js?v=\$release'"),
    );
  });

  test('About metadata is derived from governed catalogs and schema', () {
    expect(
      HarborReleaseInfo.dataSchemaVersion,
      HarborData.currentSchemaVersion,
    );
    expect(HarborReleaseInfo.guideCatalog, guideCatalogVersion);
    expect(HarborReleaseInfo.storiesCatalog, storyCatalogVersion);
    expect(HarborReleaseInfo.guideLabel, contains('${guideEntries.length}'));
    expect(HarborReleaseInfo.storiesLabel, contains('${storyEntries.length}'));
    expect(guideEntries.map((entry) => entry.id).toSet(), hasLength(12));
    expect(storyEntries.map((entry) => entry.id).toSet(), hasLength(6));
    expect(HarborReleaseInfo.guideStatus, contains('approval pending'));
    expect(HarborReleaseInfo.storiesStatus, contains('Awaiting'));
  });

  test('release metadata contains no URL or personal-data value', () {
    final publicMetadata = <String>[
      HarborReleaseInfo.versionLabel,
      HarborReleaseInfo.releaseStatus,
      HarborReleaseInfo.guideLabel,
      HarborReleaseInfo.storiesLabel,
      HarborReleaseInfo.guideStatus,
      HarborReleaseInfo.storiesStatus,
      HarborReleaseInfo.license,
      HarborReleaseInfo.copyright,
    ].join('\n');

    expect(publicMetadata, isNot(contains('http://')));
    expect(publicMetadata, isNot(contains('https://')));
    expect(publicMetadata, isNot(contains('journal')));
    expect(publicMetadata, isNot(contains('check-in')));
  });
}
