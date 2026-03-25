// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String fmtCurrency(double v) {
  if (v == 0) return 'AED 0.00';
  return 'AED ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
}

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} '
    '${_kMonths[d.month - 1]} ${d.year}';

const _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
