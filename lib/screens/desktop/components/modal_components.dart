import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Brand
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const teal = Color(0xFF38BDF8);

  // Semantic
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);

  // Neutrals
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;

  // Dimensions
  static const sidebarW = 220.0;
  static const topbarH = 52.0;
  static const detailW = 400.0;

  // Radius
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class ModalAutocomplete<T extends Object> extends StatefulWidget {
  final T? initialValue;
  final List<T> options;
  final String Function(T) displayStringForOption;
  final ValueChanged<T?> onSelected;
  final String hint;

  // Creation hooks
  final bool allowCreation;
  final Future<T?> Function(String typedText)? onCreateOption;

  const ModalAutocomplete({
    required this.options,
    required this.displayStringForOption,
    required this.onSelected,
    this.initialValue,
    this.hint = '',
    this.allowCreation = false,
    this.onCreateOption,
    super.key,
  });

  @override
  State<ModalAutocomplete<T>> createState() => _ModalAutocompleteState<T>();
}

class _ModalAutocompleteState<T extends Object>
    extends State<ModalAutocomplete<T>> {
  late TextEditingController _fieldController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Object>(
          initialValue:
              widget.initialValue != null
                  ? TextEditingValue(
                    text: widget.displayStringForOption(widget.initialValue!),
                  )
                  : const TextEditingValue(),
          displayStringForOption: (obj) {
            if (obj is String)
              return obj; // Handles the virtual creation string token
            return widget.displayStringForOption(obj as T);
          },
          optionsBuilder: (TextEditingValue textEditingValue) {
            final text = textEditingValue.text.trim();

            // Filter existing options match
            final filtered =
                widget.options.where((T option) {
                  return widget
                      .displayStringForOption(option)
                      .toLowerCase()
                      .contains(text.toLowerCase());
                }).toList();

            // If creation is allowed, text isn't empty, and no exact match exists, append a virtual action string
            if (widget.allowCreation && text.isNotEmpty) {
              final hasExactMatch = widget.options.any(
                (o) =>
                    widget.displayStringForOption(o).toLowerCase() ==
                    text.toLowerCase(),
              );
              if (!hasExactMatch) {
                // Return original matches + a pure string token representing the dynamic creation action
                return [...filtered, text];
              }
            }

            return filtered.isEmpty && text.isEmpty ? widget.options : filtered;
          },
          onSelected: (Object selection) async {
            if (selection is String) {
              // User deliberately selected the action item row to create a new client
              if (widget.onCreateOption != null) {
                final createdItem = await widget.onCreateOption!(selection);
                if (createdItem != null) {
                  widget.onSelected(createdItem);
                  _fieldController.text = widget.displayStringForOption(
                    createdItem,
                  );
                } else {
                  // If canceled/failed, reset field to blank or previous value
                  _fieldController.text =
                      widget.initialValue != null
                          ? widget.displayStringForOption(widget.initialValue!)
                          : '';
                }
              }
            } else {
              // Regular selection
              widget.onSelected(selection as T);
            }
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _fieldController = controller;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 13, color: _T.ink),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: _T.slate400),
                filled: true,
                fillColor: _T.slate50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_T.r),
                  borderSide: const BorderSide(color: _T.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_T.r),
                  borderSide: const BorderSide(color: _T.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_T.r),
                  borderSide: const BorderSide(color: _T.blue, width: 2),
                ),
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: _T.slate400,
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelectedOption, iterableOptions) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(_T.r),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: constraints.maxWidth,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: _T.slate200),
                    borderRadius: BorderRadius.circular(_T.r),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: iterableOptions.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Object option = iterableOptions.elementAt(index);

                      // Check if it's the dynamic creation option row
                      if (option is String) {
                        return InkWell(
                          onTap: () => onSelectedOption(option),
                          child: Container(
                            color: _T.blue50.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  size: 14,
                                  color: _T.blue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Create new customer: "$option"',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _T.blue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Standard dropdown list rows
                      return InkWell(
                        onTap: () => onSelectedOption(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            widget.displayStringForOption(option as T),
                            style: const TextStyle(fontSize: 13, color: _T.ink),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ModalField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const ModalField({
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _T.ink3,
            ),
          ),
          if (required)
            const Text(' *', style: TextStyle(color: _T.red, fontSize: 12)),
        ],
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

class ModalInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const ModalInput({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _T.slate400),
      filled: true,
      fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.blue, width: 2),
      ),
    ),
  );
}

class ModalTextarea extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const ModalTextarea({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    maxLines: 3,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _T.slate400),
      filled: true,
      fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.blue, width: 2),
      ),
    ),
  );
}

class ModalDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const ModalDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    items: items,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      filled: true,
      fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_T.r),
        borderSide: const BorderSide(color: _T.blue, width: 2),
      ),
    ),
    dropdownColor: Colors.white,
    borderRadius: BorderRadius.circular(_T.r),
    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: _T.slate400),
  );
}
