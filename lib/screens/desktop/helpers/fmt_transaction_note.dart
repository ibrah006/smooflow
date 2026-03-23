/// Formats a stock transaction note for display.
///
/// If the note contains a [WRITEOFF:REASON] prefix (written by _WriteOffDialog),
/// returns a clean label like "Damaged · user note here" or just "Damaged"
/// if there's no trailing user note.
///
/// If the note contains a [BATCH:...] prefix (written by _StockAdjustDialog),
/// strips the machine-readable tag and returns only the human note,
/// or null if there was no human note (i.e. the note was purely structured).
///
/// Falls back to the raw note string for anything else.
String? fmtTransactionNote(String? note) {
  if (note == null || note.trim().isEmpty) return null;

  // ── Write-off: [WRITEOFF:DAMAGED] optional user note ──────────────────────
  final writeOffMatch = RegExp(
    r'^\[WRITEOFF:([A-Z]+)\]\s*(.*)$',
  ).firstMatch(note.trim());
  if (writeOffMatch != null) {
    final reasonRaw = writeOffMatch.group(1)!; // e.g. "DAMAGED"
    final userNote = writeOffMatch.group(2)!.trim();

    // Map the encoded reason back to a display label
    final label = switch (reasonRaw) {
      'DAMAGED' => 'Damaged',
      'WASTAGE' => 'Wastage',
      'CORRECTION' => 'Correction',
      'EXPIRED' => 'Expired',
      'OTHER' => 'Other',
      _ => reasonRaw, // unknown reason — show as-is
    };

    return userNote.isNotEmpty ? '$label · $userNote' : label;
  }

  // ── Batch receive: [BATCH:supplier="...",po="..."] optional user note ──────
  final batchMatch = RegExp(
    r'^\[BATCH:[^\]]+\]\s*(.*)$',
  ).firstMatch(note.trim());
  if (batchMatch != null) {
    final userNote = batchMatch.group(1)!.trim();
    return userNote.isNotEmpty ? userNote : null;
  }

  // ── Plain note — return as-is ──────────────────────────────────────────────
  return note.trim().isEmpty ? null : note.trim();
}
