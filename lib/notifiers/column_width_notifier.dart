// ─────────────────────────────────────────────────────────────────────────────
// column_width_notifier.dart
//
// Shared column width state for TaskListView resizable columns.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// Minimum and maximum widths per column (pixels)
const double kColMinWidth = 48.0;
const double kColMaxWidth = 480.0;
const double kResizeHandleWidth = 8.0;

/// Holds pixel widths for every column, including hidden columns (width = 0).
/// Notifies listeners when a column is resized or shown/hidden.
class ColumnWidthNotifier extends ChangeNotifier {
  final Map<String, double> _widths;
  final Map<String, double> _defaultWidths;

  ColumnWidthNotifier({required Map<String, double> defaultWidths})
    : _widths = Map.from(defaultWidths),
      _defaultWidths = Map.from(defaultWidths);

  double operator [](String id) => _widths[id] ?? 0;

  Map<String, double> get widths => Map.unmodifiable(_widths);

  void resize(String id, double delta) {
    final current = _widths[id] ?? 0;
    final clamped = (current + delta).clamp(kColMinWidth, kColMaxWidth);
    if ((clamped - current).abs() < 0.1) return;
    _widths[id] = clamped;
    notifyListeners();
  }

  void setWidth(String id, double width) {
    _widths[id] = width.clamp(0, kColMaxWidth);
    notifyListeners();
  }

  void showColumn(String id) {
    _widths[id] = _defaultWidths[id] ?? 100;
    notifyListeners();
  }

  void hideColumn(String id) {
    _widths[id] = 0;
    notifyListeners();
  }

  void resetToDefaults() {
    _widths.addAll(_defaultWidths);
    notifyListeners();
  }
}

/// InheritedNotifier so any descendant can read widths without prop drilling.
class ColumnWidthScope extends InheritedNotifier<ColumnWidthNotifier> {
  const ColumnWidthScope({
    super.key,
    required ColumnWidthNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ColumnWidthNotifier of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ColumnWidthScope>();
    assert(scope != null, 'No ColumnWidthScope found in context');
    return scope!.notifier!;
  }

  static ColumnWidthNotifier? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ColumnWidthScope>()
        ?.notifier;
  }
}
