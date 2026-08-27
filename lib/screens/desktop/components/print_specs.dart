// print_specs.dart
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/print_spec.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/print_ref_history.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/ghost_text_field.dart';
import 'package:flutter_ocr_native/flutter_ocr_native.dart';

class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const teal = Color(0xFF38BDF8);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
  static const indigo = Color(0xFF6366F1);
  static const indigo50 = Color(0xFFEEF2FF);
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
  static const sidebarW = 220.0;
  static const topbarH = 52.0;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class PrinterStub {
  final String id;
  final String name;
  final String nickname;
  final bool isAvailable;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackgroundColor;

  const PrinterStub({
    required this.id,
    required this.name,
    required this.nickname,
    required this.isAvailable,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackgroundColor,
  });
}

class PrinterRow extends StatefulWidget {
  final PrinterStub printer;
  final bool isSelected;
  final VoidCallback? onTap;

  const PrinterRow({
    required this.printer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<PrinterRow> createState() => _PrinterRowState();
}

class _PrinterRowState extends State<PrinterRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final selected = widget.isSelected;
    final p = widget.printer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor:
            disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  disabled
                      ? _T.slate50
                      : selected
                      ? _T.blue50
                      : _hovered
                      ? const Color(0xFFF8FBFF)
                      : _T.white,
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(
                color:
                    selected
                        ? _T.blue.withOpacity(0.45)
                        : disabled
                        ? _T.slate100
                        : _hovered
                        ? _T.slate300
                        : _T.slate200,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        disabled
                            ? _T.slate100
                            : selected
                            ? _T.blue.withOpacity(0.12)
                            : _T.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.print_outlined,
                    size: 16,
                    color:
                        disabled
                            ? _T.slate300
                            : selected
                            ? _T.blue
                            : _T.slate500,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: disabled ? _T.slate400 : _T.ink,
                        ),
                      ),
                      if (p.nickname.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          p.nickname,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.statusBackgroundColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: p.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: p.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: _T.blue,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEC SHEETS — frontend-only mock pipeline (upload → extracting → done/failed)
// ─────────────────────────────────────────────────────────────────────────────
enum SpecSheetStatus { uploading, extracting, completed, failed }

/// Color assigned per sheet so the badge on the sheet thumbnail and the "Sx"
/// chip on each extracted row visually pair up. Cycled by upload order.
const List<Color> _kSheetColors = [
  _T.blue,
  _T.purple,
  _T.teal,
  _T.amber,
  _T.indigo,
  _T.green,
];

/// Local-only view model for an uploaded spec sheet image. No backend entity
/// exists yet — this never leaves the widget tree. Replace `_processSpecSheet`
/// with a real upload + extraction API call once that endpoint exists.
class SpecSheetDraft {
  final int id;
  final String fileName;
  final String localPath;
  final Color color;
  SpecSheetStatus status;
  List<int> extractedSpecIds;

  SpecSheetDraft({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.color,
    this.status = SpecSheetStatus.uploading,
    List<int>? extractedSpecIds,
  }) : extractedSpecIds = extractedSpecIds ?? [];
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW CORPORATE INLINE MULTI-SIZE EDITOR
// ─────────────────────────────────────────────────────────────────────────────
class PrintSpecsEditor extends ConsumerStatefulWidget {
  final Task task;
  final Function(
    List<PrintSpec>? specs,
    bool sharedRef, {
    int? deletePrintSpecId,
    List<PrintSpec>? newPrintSpecs,
  })
  onUpdate;

  const PrintSpecsEditor({required this.task, required this.onUpdate});

  @override
  ConsumerState<PrintSpecsEditor> createState() => _PrintSpecsEditorState();
}

class _PrintSpecsEditorState extends ConsumerState<PrintSpecsEditor> {
  bool _sharedRef = true;
  List<PrintSpec> _items = [];

  // Tracks transient local item IDs that have fired an API request to prevent duplicate creation
  final Set<int> _committedTransientIds = {};

  // ── Spec sheets state ─────────────────────────────────────────────────────
  List<SpecSheetDraft> _specSheets = [];
  int _nextSheetId = -1;
  bool _pickingSheet = false;

  final _ocrReader = OcrReader();

  @override
  void initState() {
    super.initState();
    _initSpecs();
  }

  @override
  void dispose() {
    _ocrReader.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PrintSpecsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _initSpecs();
    }
  }

  void _initSpecs() {
    _committedTransientIds.clear();
    _specSheets = [];
    try {
      _items = List.from(widget.task.printSpecs);

      if (_items.isNotEmpty) {
        final firstRef = _items.first.ref;
        _sharedRef = _items.every((item) => item.ref == firstRef);
      } else {
        _sharedRef = true;
      }
      return;
    } catch (_) {}
  }

  void _notifyChange() {
    widget.onUpdate(_items, _sharedRef);
  }

  // ── Spec sheet upload + mock extraction ───────────────────────────────────
  Future<void> _pickSpecSheets() async {
    if (_pickingSheet) return;
    setState(() => _pickingSheet = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      final files = result?.files ?? [];
      for (final f in files) {
        final path = f.path;
        if (path == null) continue;
        final sheet = SpecSheetDraft(
          id: _nextSheetId--,
          fileName: f.name,
          localPath: path,
          color: _kSheetColors[_specSheets.length % _kSheetColors.length],
        );
        setState(() => _specSheets = [..._specSheets, sheet]);
        _processSpecSheet(sheet);
      }
    } finally {
      if (mounted) setState(() => _pickingSheet = false);
    }
  }

  void _commitExtractedSpecs(List<PrintSpec> extracted, SpecSheetDraft sheet) {
    late final sharedRef;
    if (_sharedRef) {
      try {
        sharedRef = _items.first.ref ?? '';
      } catch (_) {
        sharedRef = '';
      }
    }

    _committedTransientIds.addAll(
      extracted.map((e) {
        if (e.id >= 0) {
          throw Exception(
            "Attempting to commit (create) an already persisted PrintSpec with ID ${e.id}",
          );
        }

        return e.id;
      }),
    );
    widget.onUpdate(
      null,
      _sharedRef,
      newPrintSpecs:
          extracted.map((p) {
            return p..ref = _sharedRef ? sharedRef : p.ref;
          }).toList(),
    );
  }

  // OPEN ITEM: mock pipeline only — replace the two delays + random outcome
  // below with a real upload call followed by an extraction API call once
  // the backend supports it. UI states (uploading/extracting/done/failed)
  // are already wired to whatever this method sets on `sheet.status`.
  Future<void> _processSpecSheet(SpecSheetDraft sheet) async {
    setState(() => sheet.status = SpecSheetStatus.extracting);

    try {
      // Works across Android, iOS, macOS, and Windows
      final OcrResult result = await _ocrReader.readFromPath(sheet.localPath);

      if (!mounted) return;

      final extracted = _parseSizesFromOcr(result.text, sheet.id);

      if (extracted.isEmpty) {
        setState(() => sheet.status = SpecSheetStatus.completed);
        print("[_processSpecSheet] empty extraction");
        return;
      }

      setState(() {
        sheet.status = SpecSheetStatus.completed;
        sheet.extractedSpecIds = extracted.map((e) => e.id).toList();
        _items = [..._items, ...extracted];
      });
    } catch (e) {
      print("[_processSpecSheet] extraction failed, error: $e");
      if (mounted) {
        setState(() => sheet.status = SpecSheetStatus.failed);
      }
    }
  }

  List<PrintSpec> _parseSizesFromOcr(String fullText, int sheetId) {
    final List<PrintSpec> specs = [];

    // Matches dimensions like "60x90 cm", "210×297 mm", "30 x 40 in", "120 * 80 cm"
    final sizeRegExp = RegExp(
      r'(\d+(?:\.\d+)?)\s*[xX×*]\s*(\d+(?:\.\d+)?)\s*(cm|mm|in|inch|inches|m|ft)?',
      caseSensitive: false,
    );

    final matches = sizeRegExp.allMatches(fullText);

    for (final match in matches) {
      final width = match.group(1);
      final height = match.group(2);
      final unit = match.group(3) ?? 'cm'; // Default fallback unit

      final formattedSize = '$width×$height ${unit.toLowerCase()}';

      specs.add(
        PrintSpec.create(
          ref: _sharedRef && _items.isNotEmpty ? _items.first.ref : '',
          size: formattedSize,
          quantity: 1,
          sourceSheetId: sheetId,
        ),
      );
    }

    return specs;
  }

  void _retrySheet(SpecSheetDraft sheet) {
    setState(() => sheet.status = SpecSheetStatus.uploading);
    _processSpecSheet(sheet);
  }

  void _deleteSpecSheet(SpecSheetDraft sheet) {
    setState(() {
      _specSheets = _specSheets.where((s) => s.id != sheet.id).toList();
      _items = _items.where((i) => i.sourceSheetId != sheet.id).toList();
    });
  }

  List<PrintSpec> _mockExtractSizes(int sheetId) {
    final rand = Random();
    final count = 1 + rand.nextInt(3);
    const commonSizes = [
      ('60', '90', 'cm'),
      ('100', '200', 'cm'),
      ('45', '60', 'cm'),
      ('120', '80', 'cm'),
      ('210', '297', 'mm'),
      ('30', '40', 'in'),
    ];
    return List.generate(count, (i) {
      final s = commonSizes[rand.nextInt(commonSizes.length)];
      return PrintSpec.create(
        ref: _sharedRef && _items.isNotEmpty ? _items.first.ref : '',
        size: '${s.$1}×${s.$2} ${s.$3}',
        quantity: 1 + rand.nextInt(5),
        sourceSheetId: sheetId,
      );
    });
  }

  void _showSheetPreview(SpecSheetDraft sheet) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder:
          (_) => Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.all(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_T.rLg),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
                maxHeight: 640,
                minWidth: 320,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sheet.fileName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _T.ink,
                            ),
                          ),
                        ),
                        if (sheet.status == SpecSheetStatus.completed)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: sheet.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: sheet.color.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                '${sheet.extractedSpecIds.length} sizes found',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: sheet.color,
                                ),
                              ),
                            ),
                          ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: _T.slate500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _T.slate200),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.file(
                        File(sheet.localPath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSpecSheetsSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SPEC SHEETS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: _T.slate400,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _T.indigo50,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'BETA',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: _T.indigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload a spec sheet or reference photo — sizes are pulled out automatically.',
            style: TextStyle(fontSize: 10.5, color: _T.slate400),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._specSheets.asMap().entries.map((e) {
                final index = e.key;
                final sheet = e.value;
                return _SpecSheetThumb(
                  key: ValueKey(sheet.id),
                  sheet: sheet,
                  sheetIndex: index + 1,
                  onDelete: () => _deleteSpecSheet(sheet),
                  onTap:
                      () =>
                          sheet.status == SpecSheetStatus.failed
                              ? _retrySheet(sheet)
                              : _showSheetPreview(sheet),
                );
              }),
              _AddSpecSheetTile(busy: _pickingSheet, onTap: _pickSpecSheets),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _T.slate200),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      ref
          .read(taskNotifierProvider)
          .removeCurrentlyDeletingSpec(
            targetSpecs: _items,
            onRemove: (printSpecIndex) {
              widget.task.printSpecs.removeAt(printSpecIndex);
              _items = widget.task.printSpecs;
            },
          );
    } catch (E) {
      // pass
    }

    return Container(
      decoration: BoxDecoration(
        color: _T.slate50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecSheetsSection(),
          const SizedBox(height: 2),

          // ── Shared Ref Toggle ──
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() => _sharedRef = !_sharedRef);
                if (_sharedRef && _items.isNotEmpty) {
                  final masterRef = _items.first.ref;

                  for (int i = 0; i < _items.length; i++) {
                    _items[i] = _items[i].copyWith(ref: masterRef);
                  }

                  final updatedItems =
                      _items
                          .map((item) => item.copyWith(ref: masterRef))
                          .toList();

                  widget.onUpdate(updatedItems, _sharedRef);
                }
              },
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _sharedRef
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(_sharedRef),
                      color: _sharedRef ? _T.blue : _T.slate400,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Use a single reference for all sizes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _T.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Master Shared Reference Field ──
          if (_sharedRef) ...[
            Container(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Row(
                children: [
                  const Text(
                    'Ref:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _T.slate400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RefAutocompleteField(
                      key: ValueKey(
                        'master_ref_${_items.isNotEmpty ? _items.first.id : ''}',
                      ),
                      initialText:
                          _items.isNotEmpty ? (_items.first.ref ?? '') : '',
                      onSubmitted: (val) {
                        late final List<PrintSpec> updatedItems;
                        if (_items.isNotEmpty) {
                          for (int i = 0; i < _items.length; i++) {
                            _items[i] = _items[i].copyWith(ref: val);
                          }
                          updatedItems =
                              _items
                                  .map((item) => item.copyWith(ref: val))
                                  .toList();

                          widget.onUpdate(updatedItems, true);
                        } else {
                          final newPrintSpec = PrintSpec.create(
                            ref: val,
                            size: "0×0 cm",
                            quantity: 1,
                          );
                          _committedTransientIds.add(newPrintSpec.id);

                          widget.onUpdate(
                            null,
                            true,
                            newPrintSpecs: [newPrintSpec],
                          );
                        }
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: _T.ink3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _T.slate200),
            const SizedBox(height: 8),
          ],

          // ── Table Headers ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(
                  width: 28 + 9.5,
                ), // aligns with the source-sheet chip column
                if (!_sharedRef)
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'REF',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: _T.slate400,
                      ),
                    ),
                  ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'SIZE (W × H cm)',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _T.slate400,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'QTY',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _T.slate400,
                    ),
                  ),
                ),
                // Expanded spacer to account for the animated trailing actions
                // const SizedBox(width: 56),
              ],
            ),
          ),

          // ── Table Rows ──
          ..._items.asMap().entries.map((e) {
            final index = e.key;
            final item = e.value;

            // Currently creating
            try {
              if (item.id < 0) {
                final createdId =
                    ref
                        .read(taskNotifierProvider)
                        .currentlyCreatingSpecs[widget.task.id]
                        ?.lastWhere((spec) {
                          return spec.tempLocalId == item.id;
                        })
                        .createdId;

                if (createdId != null) {
                  item.initializeId(createdId);

                  ref
                      .read(taskNotifierProvider)
                      .removeCurrentlyCreatingSpec(widget.task.id, createdId);
                }
              }
            } catch (e) {
              // pass
            }

            SpecSheetDraft? sourceSheet;
            int? sheetIdx;
            if (item.sourceSheetId != null) {
              for (int i = 0; i < _specSheets.length; i++) {
                if (_specSheets[i].id == item.sourceSheetId) {
                  sourceSheet = _specSheets[i];
                  sheetIdx = i + 1;
                  break;
                }
              }
            }

            return _SpecRowInline(
              key: ValueKey(item.id),
              taskId: widget.task.id,
              item: item,
              sharedRef: _sharedRef,
              sourceSheet: sourceSheet,
              sheetIndex: sheetIdx,
              onChanged: (updatedItem) {
                setState(() {
                  _items[index] = updatedItem;
                });

                // Transient items created locally possess negative IDs
                final bool isLocalDraft = updatedItem.id < 0;

                if (isLocalDraft) {
                  // Guard against multi-field edit duplicate creation streams
                  if (_committedTransientIds.contains(updatedItem.id)) {
                    return;
                  }

                  const String defaultSize = "0×0 cm";
                  const int defaultQty = 1;
                  final String defaultRef =
                      _sharedRef && _items.isNotEmpty
                          ? (_items.first.ref ?? '')
                          : '';

                  bool hasChanged = false;

                  // Evaluate if size or quantity deviated from fallback metrics
                  if (updatedItem.size != defaultSize ||
                      updatedItem.quantity != defaultQty) {
                    hasChanged = true;
                  }

                  // Evaluate if unique custom tracking code reference was set
                  if (!_sharedRef &&
                      updatedItem.ref != defaultRef &&
                      updatedItem.ref != null &&
                      updatedItem.ref!.trim().isNotEmpty) {
                    hasChanged = true;
                  }

                  if (hasChanged) {
                    late final sharedRef;
                    if (_sharedRef) {
                      try {
                        sharedRef = _items.first.ref ?? '';
                      } catch (_) {
                        sharedRef = '';
                      }
                    }

                    _committedTransientIds.add(updatedItem.id);
                    widget.onUpdate(
                      null,
                      _sharedRef,
                      newPrintSpecs: [
                        updatedItem
                          ..ref = _sharedRef ? sharedRef : updatedItem.ref,
                      ],
                    );
                  }
                } else {
                  // Standard direct update synchronization flow for real entity objects
                  widget.onUpdate([updatedItem], _sharedRef);
                }
              },
              onDelete: () {
                final toBeRemoved = _items.elementAt(index);
                setState(() {});
                if (toBeRemoved.id > 0) {
                  // Request API deletion for persisted items
                  widget.onUpdate(
                    null,
                    _sharedRef,
                    deletePrintSpecId: toBeRemoved.id,
                  );
                }
              },
            );
          }),

          // ── Add Item Button ──
          const SizedBox(height: 4),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  final printSpec = PrintSpec.create(
                    ref:
                        _sharedRef && _items.isNotEmpty ? _items.first.ref : '',
                    size: "0×0 cm",
                    quantity: 1,
                  );
                  _items.add(printSpec);
                  // Dynamic API service synchronization is deferred until layout is modified
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _T.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 12,
                        color: _T.blue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Add size manually',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _T.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEC SHEET THUMBNAIL + ADD TILE
// ─────────────────────────────────────────────────────────────────────────────
class _SpecSheetThumb extends StatefulWidget {
  final SpecSheetDraft sheet;
  final int sheetIndex;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SpecSheetThumb({
    super.key,
    required this.sheet,
    required this.sheetIndex,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_SpecSheetThumb> createState() => _SpecSheetThumbState();
}

class _SpecSheetThumbState extends State<_SpecSheetThumb> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final busy =
        sheet.status == SpecSheetStatus.uploading ||
        sheet.status == SpecSheetStatus.extracting;
    final failed = sheet.status == SpecSheetStatus.failed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: busy ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 104,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color:
                  failed
                      ? _T.red.withOpacity(0.5)
                      : (_hovered
                          ? sheet.color.withOpacity(0.6)
                          : sheet.color.withOpacity(0.35)),
              width: 1.4,
            ),
            boxShadow:
                _hovered
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(_T.r - 1),
                child: SizedBox.expand(
                  child: Image.file(
                    File(sheet.localPath),
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: _T.slate100,
                          child: const Icon(
                            Icons.image_outlined,
                            color: _T.slate400,
                          ),
                        ),
                  ),
                ),
              ),

              if (busy || failed)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(_T.r - 1),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (busy)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              failed
                                  ? 'Failed — tap to retry'
                                  : (sheet.status == SpecSheetStatus.uploading
                                      ? 'Uploading…'
                                      : 'Extracting sizes…'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (!busy)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(_T.r - 1),
                      ),
                    ),
                    child: Text(
                      sheet.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Sheet index chip — matches the "Sx" tag on extracted rows
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sheet.color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'S${widget.sheetIndex}',
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              if (sheet.status == SpecSheetStatus.completed)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: sheet.color.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${sheet.extractedSpecIds.length} size${sheet.extractedSpecIds.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: sheet.color,
                      ),
                    ),
                  ),
                ),

              if (_hovered && !busy)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 11,
                          color: _T.red,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSpecSheetTile extends StatefulWidget {
  final bool busy;
  final VoidCallback onTap;
  const _AddSpecSheetTile({required this.busy, required this.onTap});

  @override
  State<_AddSpecSheetTile> createState() => _AddSpecSheetTileState();
}

class _AddSpecSheetTileState extends State<_AddSpecSheetTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 104,
          height: 96,
          decoration: BoxDecoration(
            color: _hovered ? _T.blue50 : _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: _hovered ? _T.blue.withOpacity(0.35) : _T.slate200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.busy
                    ? Icons.hourglass_empty_rounded
                    : Icons.document_scanner_outlined,
                size: 18,
                color: _hovered ? _T.blue : _T.slate400,
              ),
              const SizedBox(height: 6),
              Text(
                widget.busy ? 'Opening…' : 'Add spec sheet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? _T.blue : _T.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecRowInline extends ConsumerStatefulWidget {
  final PrintSpec item;
  final bool sharedRef;
  final ValueChanged<PrintSpec> onChanged;
  final VoidCallback onDelete;
  final int taskId;
  final SpecSheetDraft? sourceSheet;
  final int? sheetIndex;

  _SpecRowInline({
    super.key,
    required this.item,
    required this.sharedRef,
    required this.onChanged,
    required this.onDelete,
    required this.taskId,
    this.sourceSheet,
    this.sheetIndex,
  });

  @override
  ConsumerState<_SpecRowInline> createState() => _SpecRowInlineState();
}

class _SpecRowInlineState extends ConsumerState<_SpecRowInline> {
  bool _hovered = false;

  // Local state for tracking edits before committing to API
  late PrintSpec _editedItem;
  int _rebuildCounter =
      0; // Increments to force GhostTextFields to reset text upon discard
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editedItem = widget.item.copyWith();
  }

  @override
  void didUpdateWidget(covariant _SpecRowInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent passes down a new version (e.g. after a successful API save),
    // we reset our local state to match the fresh source of truth.
    if (oldWidget.item != widget.item) {
      _editedItem = widget.item.copyWith();
      _rebuildCounter++;
      _isSaving = false;
    }
  }

  String _fmt(double n) => n == n.toInt() ? n.toInt().toString() : n.toString();

  bool get _isDraft => widget.item.id < 0;

  bool get _hasChanges {
    if (_isDraft)
      return false; // Drafts trigger API creation immediately on change
    return _editedItem.ref != widget.item.ref ||
        _editedItem.width != widget.item.width ||
        _editedItem.height != widget.item.height ||
        _editedItem.quantity != widget.item.quantity;
  }

  void _saveLocalChanges() {
    setState(() => _isSaving = true);
    widget.onChanged(_editedItem);

    // Fallback: If parent fails to update widget.item, reset the loader after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isSaving) {
        setState(() => _isSaving = false);
      }
    });
  }

  void _discardLocalChanges() {
    setState(() {
      _editedItem = widget.item.copyWith();
      _rebuildCounter++; // Force GhostTextFields to re-initialize with reverted text
    });
  }

  Widget _buildHighlight({required bool isModified, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: isModified ? _T.amber.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isModified ? _T.amber.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSourceChip() {
    if (widget.sourceSheet == null)
      return const SizedBox(width: 16, height: 16);
    final sheet = widget.sourceSheet!;
    return Tooltip(
      message: 'Extracted from ${sheet.fileName}',
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sheet.color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: sheet.color.withOpacity(0.5)),
        ),
        child: Text(
          'S${widget.sheetIndex}',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: sheet.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentlyCreating = ref
        .watch(taskNotifierProvider)
        .isCurrentlyCreatingSpec(widget.taskId, widget.item.id);

    final isCurrentlyDeleting = ref
        .watch(taskNotifierProvider)
        .isCurrentlyDeletingSpec(widget.item.id);

    final bool isLocked =
        isCurrentlyCreating || _isSaving || isCurrentlyDeleting;

    return MouseRegion(
      onEnter: isLocked ? null : (_) => setState(() => _hovered = true),
      onExit: isLocked ? null : (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color:
              isCurrentlyDeleting
                  ? _T.red50.withOpacity(0.5)
                  : ((_hovered && !isLocked) ? _T.white : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isCurrentlyDeleting
                    ? _T.red.withOpacity(0.2)
                    : ((_hovered && !isLocked) ? _T.slate200 : Colors.white),
          ),
        ),
        child: IgnorePointer(
          ignoring: isLocked,
          child: Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLocked ? 0.5 : 1.0,
                  child: Row(
                    children: [
                      SizedBox(width: 22, child: _buildSourceChip()),
                      const SizedBox(width: 6),

                      // Internal Item Ref (Hidden if shared)
                      if (!widget.sharedRef)
                        Expanded(
                          flex: 3,
                          child: _buildHighlight(
                            isModified:
                                !_isDraft && _editedItem.ref != widget.item.ref,
                            child: GhostTextField(
                              key: ValueKey(
                                '${widget.item.id}_ref_$_rebuildCounter',
                              ),
                              initialText: _editedItem.ref ?? '',
                              onSubmitted: (v) {
                                _editedItem = _editedItem.copyWith(ref: v);
                                if (_isDraft) {
                                  widget.onChanged(_editedItem);
                                } else {
                                  setState(() {});
                                }
                              },
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontFamily: 'monospace',
                                color: _T.ink3,
                              ),
                              mode: GhostFieldMode.inline,
                            ),
                          ),
                        ),

                      // Width x Height
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            _buildHighlight(
                              isModified:
                                  !_isDraft &&
                                  _editedItem.width != widget.item.width,
                              child: GhostTextField(
                                key: ValueKey(
                                  '${widget.item.id}_w_$_rebuildCounter',
                                ),
                                initialText: _fmt(_editedItem.width),
                                onSubmitted: (v) {
                                  _editedItem = _editedItem.copyWith(
                                    size:
                                        '$v×${_fmt(_editedItem.height)} ${_editedItem.unit ?? 'cm'}',
                                  );
                                  if (_isDraft) {
                                    widget.onChanged(_editedItem);
                                  } else {
                                    setState(() {});
                                  }
                                },
                                isDecimalOnlyField: true,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _T.ink,
                                ),
                                mode: GhostFieldMode.inline,
                                inlineMinWidth: 24,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '×',
                                style: TextStyle(
                                  color: _T.slate400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            _buildHighlight(
                              isModified:
                                  !_isDraft &&
                                  _editedItem.height != widget.item.height,
                              child: GhostTextField(
                                key: ValueKey(
                                  '${widget.item.id}_h_$_rebuildCounter',
                                ),
                                initialText: _fmt(_editedItem.height),
                                onSubmitted: (v) {
                                  _editedItem = _editedItem.copyWith(
                                    size:
                                        '${_fmt(_editedItem.width)}×$v ${_editedItem.unit ?? 'cm'}',
                                  );
                                  if (_isDraft) {
                                    widget.onChanged(_editedItem);
                                  } else {
                                    setState(() {});
                                  }
                                },
                                isDecimalOnlyField: true,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _T.ink,
                                ),
                                mode: GhostFieldMode.inline,
                                inlineMinWidth: 24,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            _buildHighlight(
                              isModified:
                                  !_isDraft &&
                                  _editedItem.quantity != widget.item.quantity,
                              child: GhostTextField(
                                hint: "0",
                                key: ValueKey(
                                  '${widget.item.id}_qty_$_rebuildCounter',
                                ),
                                initialText:
                                    _editedItem.quantity?.toString() == null ||
                                            _editedItem.quantity == 0
                                        ? ""
                                        : _editedItem.quantity.toString(),
                                onSubmitted: (v) {
                                  _editedItem = _editedItem.copyWith(
                                    quantity: int.tryParse(v) ?? 0,
                                  );
                                  if (_isDraft) {
                                    widget.onChanged(_editedItem);
                                  } else {
                                    setState(() {});
                                  }
                                },
                                isDecimalOnlyField: true,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _T.ink,
                                ),
                                mode: GhostFieldMode.inline,
                                inlineMinWidth: 20,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'pcs',
                              style: TextStyle(
                                fontSize: 11,
                                color: _T.slate400,
                              ),
                            ),

                            Spacer(),

                            // Trailing Actions (Loader / Save & Discard / Delete)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _hasChanges ? 56 : 28,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child:
                                    isLocked
                                        ? const Center(
                                          key: ValueKey('loader'),
                                          child: SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    _T.slate400,
                                                  ),
                                            ),
                                          ),
                                        )
                                        : _hasChanges
                                        ? Row(
                                          key: const ValueKey('actions'),
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Tooltip(
                                              message: "Discard changes",
                                              child: InkWell(
                                                onTap: _discardLocalChanges,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4.0),
                                                  child: Icon(
                                                    Icons.undo_rounded,
                                                    size: 14,
                                                    color: _T.slate400,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Tooltip(
                                              message: "Save changes",
                                              child: InkWell(
                                                onTap: _saveLocalChanges,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _T.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_rounded,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                        : AnimatedOpacity(
                                          key: const ValueKey('delete_btn'),
                                          opacity: _hovered ? 1.0 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 14,
                                              color: _T.slate400,
                                            ),
                                            hoverColor: _T.red50,
                                            color: _T.red,
                                            onPressed: widget.onDelete,
                                            splashRadius: 16,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drop-in replacement for a `GhostTextField` used on a print-spec "ref"
/// field. Shows a small dropdown of previously-used refs, filtered live as
/// the user types, and records whatever gets submitted so it's suggested
/// next time.
///
/// REQUIRES two small additions to `GhostTextField` (not shown here, since
/// I don't have its source) — both optional, so nothing else calling it
/// breaks:
///   1. `TextEditingController? controller` — if provided, use it instead
///      of creating an internal one.
///   2. `ValueChanged<String>? onChanged` — call it from the underlying
///      TextField's onChanged.
/// the user types, and records whatever gets submitted so it's suggested
/// next time. Hovering a suggestion reveals an "x" to remove it from the
/// saved history.
class RefAutocompleteField extends StatefulWidget {
  final String initialText;
  final String? hint;
  final TextStyle style;
  final GhostFieldMode mode;
  final double inlineMinWidth;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onEditingComplete;

  const RefAutocompleteField({
    super.key,
    required this.initialText,
    required this.onSubmitted,
    this.hint,
    required this.style,
    this.mode = GhostFieldMode.inline,
    this.inlineMinWidth = 20.0,
    this.onEditingComplete,
  });

  @override
  State<RefAutocompleteField> createState() => _RefAutocompleteFieldState();
}

class _RefAutocompleteFieldState extends State<RefAutocompleteField> {
  final LayerLink _link = LayerLink();
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _controller;

  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _refreshSuggestions(_controller.text);
    } else {
      // Small delay so a tap on a suggestion (or its delete icon) registers
      // before tearing the overlay down.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _removeOverlay();
      });
    }
  }

  Future<void> _refreshSuggestions(String query) async {
    final results = await RefHistoryStore.instance.getSuggestions(query: query);
    if (!mounted) return;
    setState(() => _suggestions = results);
    if (results.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    // Rebuilding the overlay entry (rather than mutating one in place) keeps
    // this in sync whenever _suggestions changes, e.g. after a delete.
    _overlayEntry?.remove();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: 200,
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: const Offset(0, 26),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return _SuggestionTile(
                        label: suggestion,
                        onSelect: () => _selectSuggestion(suggestion),
                        onDelete: () => _deleteSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(String value) {
    _controller.text = value;
    _removeOverlay();
    _commit(value);
    _focusNode.unfocus();
  }

  Future<void> _deleteSuggestion(String value) async {
    await RefHistoryStore.instance.removeRef(value);
    // Keep focus on the field and just refresh the list underneath — deleting
    // a suggestion shouldn't close the dropdown or touch what's typed.
    await _refreshSuggestions(_controller.text);
  }

  void _commit(String value) {
    RefHistoryStore.instance.recordRef(value);
    widget.onSubmitted(value);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GhostTextField(
        controller: _controller,
        focusNode: _focusNode,
        initialText: widget.initialText,
        hint: widget.hint,
        style: widget.style,
        mode: widget.mode,
        inlineMinWidth: widget.inlineMinWidth,
        onEditingComplete: widget.onEditingComplete,
        onChanged: _refreshSuggestions,
        onSubmitted: _commit,
      ),
    );
  }
}

/// A single suggestion row. Tracks its own hover state so the delete icon
/// only appears for the row the mouse is over.
class _SuggestionTile extends StatefulWidget {
  final String label;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _SuggestionTile({
    required this.label,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onSelect,
        child: Container(
          color: _hovered ? const Color(0xFFF1F5F9) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (_hovered)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    // Handle onTapDown rather than onTap: the field's own
                    // focus-loss/dismiss logic can otherwise race a plain
                    // tap and remove the overlay before onTap fires.
                    onTapDown: (_) => widget.onDelete(),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
