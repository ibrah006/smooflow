import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class _T {
  static const blue = Color(0xFF2563EB);
}

/// A macOS-style dialog content widget.
/// Use it inside a [Dialog] or directly with [showDialog].
class MacOSDatePickerDialogContent extends StatefulWidget {
  const MacOSDatePickerDialogContent({super.key});

  @override
  State<MacOSDatePickerDialogContent> createState() =>
      _MacOSDatePickerDialogContentState();
}

class _MacOSDatePickerDialogContentState
    extends State<MacOSDatePickerDialogContent> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    // macOS dialogs typically use a light background and subtle shadow
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Pick a Date',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                MacosDatePicker(
                  onDateChanged: (date) {
                    _selectedDate = date;
                  },
                  style: DatePickerStyle.graphical,
                ),
              ],
            ),
          ),
          // Divider line (macOS style)
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          // Button area
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // macOS-style "Get started" button
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the dialog.
Future<dynamic> showMacOSDatePickerDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: MacOSDatePickerDialogContent(),
        ),
  );
}
