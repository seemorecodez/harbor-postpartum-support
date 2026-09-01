import 'models.dart';

List<JournalEntry> searchJournalEntries(
  Iterable<JournalEntry> entries,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return entries.toList();
  return entries
      .where(
        (entry) =>
            entry.title.toLowerCase().contains(normalized) ||
            entry.body.toLowerCase().contains(normalized),
      )
      .toList();
}
