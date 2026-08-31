import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String workflow;

  setUpAll(() async {
    workflow = await File('.github/workflows/ci.yml').readAsString();
  });

  test('Pages deployment is downstream of the complete verification job', () {
    expect(workflow, contains('deploy_pages:'));
    expect(workflow, contains('needs: verify'));
    expect(
      RegExp(
        r"if: github\.event_name == 'push' && "
        r"github\.ref == 'refs/heads/main'",
      ).allMatches(workflow),
      hasLength(3),
    );
    expect(workflow, contains('environment:\n      name: github-pages'));
    expect(
      workflow,
      contains(r'url: ${{ steps.deployment.outputs.page_url }}'),
    );
  });

  test('Pages artifact is a separately finalized repository-subpath build', () {
    expect(workflow, contains(r'repository_name="${GITHUB_REPOSITORY#*/}"'));
    expect(workflow, contains(r'base_href="/$repository_name/"'));
    expect(workflow, contains(r'--base-href "$base_href"'));
    expect(workflow, contains(r'--output "$GITHUB_WORKSPACE/build/pages"'));
    expect(
      workflow,
      contains('dart run tool/finalize_web_release.dart build/pages'),
    );
    expect(
      workflow,
      contains('dart run tool/finalize_web_release.dart --verify build/pages'),
    );
    expect(workflow, contains(r'grep -F "<base href=\"$base_href\">"'));
  });

  test('Pages actions are immutable and deploy privilege is isolated', () {
    expect(
      workflow,
      contains(
        'actions/upload-pages-artifact@'
        '7b1f4a764d45c48632c6b24a0339c27f5614fb0b',
      ),
    );
    expect(
      workflow,
      contains(
        'actions/configure-pages@'
        '983d7736d9b0ae728b81ab479565c72886d7745b',
      ),
    );
    expect(
      workflow,
      contains(
        'actions/deploy-pages@'
        'd6db90164ac5ed86f2b6aed7e0febac5b3c0c03e',
      ),
    );
    expect(
      workflow,
      contains('permissions:\n      pages: write\n      id-token: write'),
    );
    expect(
      RegExp(r'^\s+pages: write$', multiLine: true).allMatches(workflow),
      hasLength(1),
    );
    expect(
      RegExp(r'^\s+id-token: write$', multiLine: true).allMatches(workflow),
      hasLength(1),
    );
  });
}
