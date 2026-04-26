/// Merges two sorted lists of messages into a single sorted list.
///
/// Both [existing] and [incoming] must already be sorted by `id` in descending order.
///
/// This function:
/// - Preserves overall sorted order (by `id`)
/// - Inserts incoming messages at the correct positions
/// - Handles gaps in IDs (they do not need to be continuous)
/// - Avoids duplicates by resolving equal IDs
///
/// Duplicate handling:
/// - If a message with the same `id` exists in both lists,
///   the incoming message (`b`) replaces the existing one (`a`).
///   (You can change this behavior if needed.)
///
/// Time complexity: O(n + m)
/// Space complexity: O(n + m)
/// Requirements: object class T.id should exist and should be of number
List<T> mergeByObjectId<T>(List<T> existing, List<T> incoming) {
  int i = 0;
  int j = 0;

  final result = <T>[];

  while (i < existing.length && j < incoming.length) {
    final a = existing[i];
    final b = incoming[j];

    if ((a as dynamic).id == (b as dynamic).id) {
      // ✅ Replace duplicate with incoming
      result.add(b);
      i++;
      j++;
    }
    // 🔥 DESC: bigger id comes first
    else if (a.id > b.id) {
      result.add(a);
      i++;
    } else {
      result.add(b);
      j++;
    }
  }

  // Remaining items
  while (i < existing.length) {
    result.add(existing[i++]);
  }

  while (j < incoming.length) {
    result.add(incoming[j++]);
  }

  return result;
}
