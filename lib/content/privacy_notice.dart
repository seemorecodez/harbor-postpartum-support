/// Public, non-personal privacy information rendered inside every Harbor app.
///
/// This is deliberately compile-time content. Reading the notice never opens a
/// network connection and never reads the local vault.
final class HarborPrivacyNoticeSection {
  const HarborPrivacyNoticeSection({required this.title, required this.body});

  final String title;
  final String body;
}

abstract final class HarborPrivacyNotice {
  static const version = '2026-09-02-alpha.1';
  static const status = 'Engineering-alpha disclosure · legal review pending';
  static const publicAddress =
      'seemorecodez.github.io/harbor-postpartum-support/privacy.html';

  static const summary =
      'Harbor is designed so private postpartum records stay in an encrypted '
      'vault on this device. Harbor has no account, advertising, analytics, '
      'tracking pixel, cloud sync, remote AI, crash-reporting SDK, or '
      'application backend for personal content.';

  static const sections = <HarborPrivacyNoticeSection>[
    HarborPrivacyNoticeSection(
      title: 'Status and scope',
      body: 'This notice describes the measured behavior of this engineering-alpha build. It has not been approved by privacy counsel and is not a certification. The browser, operating system, app store, network provider, and web host have separate practices outside Harbor.',
    ),
    HarborPrivacyNoticeSection(
      title: 'What stays in Harbor',
      body: 'Check-ins, journal entries, clinician questions, plans, care-load tasks, care-request drafts, private story responses, and setup choices are encrypted locally with AES-256-GCM before storage. Harbor does not create an account or send this content to an application server.',
    ),
    HarborPrivacyNoticeSection(
      title: 'Web requests and host metadata',
      body: 'The web/PWA downloads static application and update files from its current host. The host, content-delivery network, browser, internet provider, or network administrator may receive ordinary request metadata such as IP address, user agent, requested path, and timing. Harbor does not control or erase those third-party records. No personal Harbor entry is needed in an asset request.',
    ),
    HarborPrivacyNoticeSection(
      title: 'Encryption and its limits',
      body: 'Harbor uses a platform secure-storage adapter for its vault key and offers a local passphrase app lock. Browser storage can be evicted or cleared and is not equivalent to a phone or computer keystore. This alpha has not passed an independent security or privacy assessment.',
    ),
    HarborPrivacyNoticeSection(
      title: 'Deliberate handoffs',
      body: 'Harbor opens a phone or text handoff only after a deliberate tap. The operating system, carrier, and recipient then handle the number and anything you choose to communicate. Harbor copies clinician questions, care requests, or bounded diagnostics only after an exact preview and confirmation. Clipboard contents are outside Harbor until you clear or replace them.',
    ),
    HarborPrivacyNoticeSection(
      title: 'Retention, erase, and recovery',
      body: 'Local records remain until you erase Harbor, clear its site or app data, uninstall it, or the platform removes storage. Erase all local data removes Harbor records and the vault key, so Harbor cannot recover them. It does not erase prior clipboard copies, screenshots, device or browser backups, cached public app files, or host and network logs.',
    ),
    HarborPrivacyNoticeSection(
      title: 'No live community board',
      body: 'The anonymous message board is not active because it would create a new network, moderation, and privacy boundary. Stories in this build are bundled editorial drafts, not live posts from other women.',
    ),
    HarborPrivacyNoticeSection(
      title: 'Your controls',
      body: 'You can review app-lock status, inspect build and content versions, preview every Harbor-initiated clipboard payload, and erase all local data from the Privacy center. Because Harbor has no account or personal-content backend, the project cannot view, retrieve, or restore your entries. Never place personal health information in a public code-repository issue.',
    ),
    HarborPrivacyNoticeSection(
      title: 'Changes to this notice',
      body: 'Harbor displays this notice version in the app and on the public page. A material privacy-boundary change must update the application release, this notice, its verification tests, and the evidence ledger before deployment.',
    ),
  ];
}
