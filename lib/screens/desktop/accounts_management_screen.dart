// ─────────────────────────────────────────────────────────────────────────────
// accounts_screen.dart
//
// Accounts management — quotations and invoices for projects.
//
// LAYOUT
// ──────
//   Left panel (340px)  — tabbed list: Quotations | Invoices
//                         each row shows project, amount, status, date
//   Right panel (flex)  — detail view, switches between:
//                           • _QuotationDetail  (editable line-items table)
//                           • _InvoiceDetail    (read view + diff highlights)
//                           • _IdlePane         (nothing selected)
//
// DATA MODEL (local — wire to your providers/backend)
// ──────────────────────────────────────────────────
//   Quotation        id, projectId, lineItems, status, notes, createdAt
//   QuotationLineItem  id, taskId?, description, qty, unitPrice → amount
//   Invoice          id, quotationId, projectId, lineItems, status,
//                    dueDate, notes, createdAt
//   InvoiceLineItem  same shape + originalDescription/qty/unitPrice
//                    so we can surface diffs against the source quotation
//
// STATUS FLOWS
// ────────────
//   Quotation: draft → sent → accepted | declined
//   Invoice:   draft → sent → paid | overdue
//
// DIFF LOGIC
// ──────────
//   When an invoice is created from a quotation the quotation's line items
//   are snapshotted into InvoiceLineItem.original* fields.
//   Any subsequent edit to the invoice line items is compared against those
//   snapshots and highlighted in the invoice view.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
  static const teal = Color(0xFF0EA5E9);
  static const teal50 = Color(0xFFE0F2FE);
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
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum QuotationStatus { draft, sent, accepted, declined }

enum InvoiceStatus { draft, sent, paid, overdue }

extension QuotationStatusX on QuotationStatus {
  String get label => switch (this) {
    QuotationStatus.draft => 'Draft',
    QuotationStatus.sent => 'Sent',
    QuotationStatus.accepted => 'Accepted',
    QuotationStatus.declined => 'Declined',
  };
  Color get color => switch (this) {
    QuotationStatus.draft => _T.slate400,
    QuotationStatus.sent => _T.blue,
    QuotationStatus.accepted => _T.green,
    QuotationStatus.declined => _T.red,
  };
  Color get bg => switch (this) {
    QuotationStatus.draft => _T.slate100,
    QuotationStatus.sent => _T.blue50,
    QuotationStatus.accepted => _T.green50,
    QuotationStatus.declined => _T.red50,
  };
}

extension InvoiceStatusX on InvoiceStatus {
  String get label => switch (this) {
    InvoiceStatus.draft => 'Draft',
    InvoiceStatus.sent => 'Sent',
    InvoiceStatus.paid => 'Paid',
    InvoiceStatus.overdue => 'Overdue',
  };
  Color get color => switch (this) {
    InvoiceStatus.draft => _T.slate400,
    InvoiceStatus.sent => _T.blue,
    InvoiceStatus.paid => _T.green,
    InvoiceStatus.overdue => _T.red,
  };
  Color get bg => switch (this) {
    InvoiceStatus.draft => _T.slate100,
    InvoiceStatus.sent => _T.blue50,
    InvoiceStatus.paid => _T.green50,
    InvoiceStatus.overdue => _T.red50,
  };
}

class QuotationLineItem {
  final String id;
  final String? taskId;
  String description;
  double qty;
  double unitPrice;

  double get amount => qty * unitPrice;

  QuotationLineItem({
    required this.id,
    this.taskId,
    required this.description,
    required this.qty,
    required this.unitPrice,
  });

  QuotationLineItem copyWith({
    String? description,
    double? qty,
    double? unitPrice,
  }) => QuotationLineItem(
    id: id,
    taskId: taskId,
    description: description ?? this.description,
    qty: qty ?? this.qty,
    unitPrice: unitPrice ?? this.unitPrice,
  );

  // Snapshot for invoice diffing
  Map<String, dynamic> toSnapshot() => {
    'description': description,
    'qty': qty,
    'unitPrice': unitPrice,
  };
}

class Quotation {
  final String id;
  final String projectId;
  List<QuotationLineItem> lineItems;
  QuotationStatus status;
  String notes;
  final DateTime createdAt;
  // incremented label, e.g. "QUO-001"
  final String number;

  double get total => lineItems.fold(0, (s, i) => s + i.amount);

  Quotation({
    required this.id,
    required this.projectId,
    required this.lineItems,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.number,
  });
}

class InvoiceLineItem {
  final String id;
  final String? taskId;
  String description;
  double qty;
  double unitPrice;

  // Snapshot from quotation at time of invoice creation
  final String originalDescription;
  final double originalQty;
  final double originalUnitPrice;

  double get amount => qty * unitPrice;

  bool get descriptionChanged => description != originalDescription;
  bool get qtyChanged => qty != originalQty;
  bool get unitPriceChanged => unitPrice != originalUnitPrice;
  bool get hasAnyChange => descriptionChanged || qtyChanged || unitPriceChanged;

  InvoiceLineItem({
    required this.id,
    this.taskId,
    required this.description,
    required this.qty,
    required this.unitPrice,
    required this.originalDescription,
    required this.originalQty,
    required this.originalUnitPrice,
  });

  /// Creates an InvoiceLineItem from a QuotationLineItem, snapshotting
  /// the current values as originals.
  factory InvoiceLineItem.fromQuotationItem(QuotationLineItem q) =>
      InvoiceLineItem(
        id: 'inv_${q.id}',
        taskId: q.taskId,
        description: q.description,
        qty: q.qty,
        unitPrice: q.unitPrice,
        originalDescription: q.description,
        originalQty: q.qty,
        originalUnitPrice: q.unitPrice,
      );
}

class Invoice {
  final String id;
  final String quotationId;
  final String projectId;
  List<InvoiceLineItem> lineItems;
  InvoiceStatus status;
  String notes;
  DateTime? dueDate;
  final DateTime createdAt;
  final String number; // e.g. "INV-001"

  double get total => lineItems.fold(0, (s, i) => s + i.amount);
  double get originalTotal =>
      lineItems.fold(0, (s, i) => s + i.originalQty * i.originalUnitPrice);
  double get totalDelta => total - originalTotal;
  bool get hasChanges => lineItems.any((i) => i.hasAnyChange);

  Invoice({
    required this.id,
    required this.quotationId,
    required this.projectId,
    required this.lineItems,
    required this.status,
    required this.notes,
    required this.dueDate,
    required this.createdAt,
    required this.number,
  });

  /// Creates an Invoice from a Quotation, snapshotting all line items.
  factory Invoice.fromQuotation(Quotation q, String invoiceNumber) => Invoice(
    id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
    quotationId: q.id,
    projectId: q.projectId,
    lineItems: q.lineItems.map(InvoiceLineItem.fromQuotationItem).toList(),
    status: InvoiceStatus.draft,
    notes: q.notes,
    dueDate: DateTime.now().add(const Duration(days: 30)),
    createdAt: DateTime.now(),
    number: invoiceNumber,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // In-memory state — replace with providers
  final List<Quotation> _quotations = [];
  final List<Invoice> _invoices = [];

  Quotation? _selectedQuotation;
  Invoice? _selectedInvoice;
  bool _showingInvoice = false;

  int _quotationCounter = 1;
  int _invoiceCounter = 1;

  String get _nextQuotationNumber =>
      'QUO-${_quotationCounter.toString().padLeft(3, '0')}';
  String get _nextInvoiceNumber =>
      'INV-${_invoiceCounter.toString().padLeft(3, '0')}';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _createQuotation(Project project, List<Task> tasks) {
    final lineItems =
        tasks.map((t) {
          final desc = [
            if (t.ref != null && t.ref!.isNotEmpty) t.ref!,
            if (t.size != null && t.size!.isNotEmpty) t.size!,
          ].join(' · ');
          return QuotationLineItem(
            id: 'q_${t.id}_${DateTime.now().millisecondsSinceEpoch}',
            taskId: t.id.toString(),
            description: desc.isNotEmpty ? desc : t.name,
            qty: (t.quantity ?? 1).toDouble(),
            unitPrice: 0,
          );
        }).toList();

    // Always add one blank manual line if tasks had no useful specs
    if (lineItems.isEmpty) {
      lineItems.add(
        QuotationLineItem(
          id: 'q_manual_${DateTime.now().millisecondsSinceEpoch}',
          description: '',
          qty: 1,
          unitPrice: 0,
        ),
      );
    }

    final q = Quotation(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      projectId: project.id,
      lineItems: lineItems,
      status: QuotationStatus.draft,
      notes: '',
      createdAt: DateTime.now(),
      number: _nextQuotationNumber,
    );

    setState(() {
      _quotations.insert(0, q);
      _quotationCounter++;
      _selectedQuotation = q;
      _selectedInvoice = null;
      _showingInvoice = false;
      _tab.animateTo(0);
    });
  }

  void _createInvoiceFromQuotation(Quotation q) {
    final inv = Invoice.fromQuotation(q, _nextInvoiceNumber);
    setState(() {
      _invoices.insert(0, inv);
      _invoiceCounter++;
      _selectedInvoice = inv;
      _selectedQuotation = null;
      _showingInvoice = true;
      _tab.animateTo(1);
    });
  }

  void _updateQuotation(Quotation q) => setState(() {
    final idx = _quotations.indexWhere((x) => x.id == q.id);
    if (idx != -1) _quotations[idx] = q;
    _selectedQuotation = q;
  });

  void _updateInvoice(Invoice inv) => setState(() {
    final idx = _invoices.indexWhere((x) => x.id == inv.id);
    if (idx != -1) _invoices[idx] = inv;
    _selectedInvoice = inv;
  });

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectNotifierProvider);
    final tasks = ref.watch(taskNotifierProvider).tasks;

    final Widget detail;
    if (_showingInvoice && _selectedInvoice != null) {
      final proj = projects.cast<Project?>().firstWhere(
        (p) => p!.id == _selectedInvoice!.projectId,
        orElse: () => null,
      );
      final sourceQuotation = _quotations.cast<Quotation?>().firstWhere(
        (q) => q!.id == _selectedInvoice!.quotationId,
        orElse: () => null,
      );
      detail = _InvoiceDetail(
        key: ValueKey(_selectedInvoice!.id),
        invoice: _selectedInvoice!,
        project: proj,
        sourceQuotation: sourceQuotation,
        onUpdate: _updateInvoice,
        onClose:
            () => setState(() {
              _selectedInvoice = null;
              _showingInvoice = false;
            }),
      );
    } else if (!_showingInvoice && _selectedQuotation != null) {
      final proj = projects.cast<Project?>().firstWhere(
        (p) => p!.id == _selectedQuotation!.projectId,
        orElse: () => null,
      );
      final quotTasks =
          tasks
              .where((t) => t.projectId == _selectedQuotation!.projectId)
              .toList();
      detail = _QuotationDetail(
        key: ValueKey(_selectedQuotation!.id),
        quotation: _selectedQuotation!,
        project: proj,
        projectTasks: quotTasks,
        hasInvoice: _invoices.any(
          (i) => i.quotationId == _selectedQuotation!.id,
        ),
        onUpdate: _updateQuotation,
        onCreateInvoice: () => _createInvoiceFromQuotation(_selectedQuotation!),
        onClose:
            () => setState(() {
              _selectedQuotation = null;
            }),
      );
    } else {
      detail = const _AccountsIdlePane();
    }

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(
        children: [
          // ── Topbar ────────────────────────────────────────────────────
          _AccountsTopbar(
            projects: projects,
            tasks: tasks,
            onNewQuotation: _createQuotation,
          ),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left list panel ────────────────────────────────────
                SizedBox(
                  width: 340,
                  child: _AccountsListPanel(
                    tabController: _tab,
                    quotations: _quotations,
                    invoices: _invoices,
                    projects: projects,
                    selectedQuotId: _selectedQuotation?.id,
                    selectedInvoiceId: _selectedInvoice?.id,
                    onSelectQuotation:
                        (q) => setState(() {
                          _selectedQuotation = q;
                          _selectedInvoice = null;
                          _showingInvoice = false;
                        }),
                    onSelectInvoice:
                        (inv) => setState(() {
                          _selectedInvoice = inv;
                          _selectedQuotation = null;
                          _showingInvoice = true;
                        }),
                  ),
                ),

                // ── Right detail panel ─────────────────────────────────
                Expanded(child: detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _AccountsTopbar extends StatelessWidget {
  final List<Project> projects;
  final List<Task> tasks;
  final void Function(Project, List<Task>) onNewQuotation;

  const _AccountsTopbar({
    required this.projects,
    required this.tasks,
    required this.onNewQuotation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _T.blue50,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 14,
              color: _T.blue,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Accounts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _T.ink2,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '/',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),
          ),
          const Text(
            'Quotations & Invoices',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _T.slate400,
            ),
          ),
          const Spacer(),
          _NewQuotationButton(
            projects: projects,
            tasks: tasks,
            onCreate: onNewQuotation,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW QUOTATION BUTTON — opens project picker popup
// ─────────────────────────────────────────────────────────────────────────────
class _NewQuotationButton extends StatefulWidget {
  final List<Project> projects;
  final List<Task> tasks;
  final void Function(Project, List<Task>) onCreate;

  const _NewQuotationButton({
    required this.projects,
    required this.tasks,
    required this.onCreate,
  });

  @override
  State<_NewQuotationButton> createState() => _NewQuotationButtonState();
}

class _NewQuotationButtonState extends State<_NewQuotationButton> {
  bool _hovered = false;

  void _showProjectPicker() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder:
          (_) => _ProjectPickerDialog(
            projects: widget.projects,
            tasks: widget.tasks,
            onCreate: (proj, tasks) {
              Navigator.of(context).pop();
              widget.onCreate(proj, tasks);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _showProjectPicker,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? _T.blueHover : _T.blue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'New Quotation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT PICKER DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectPickerDialog extends StatefulWidget {
  final List<Project> projects;
  final List<Task> tasks;
  final void Function(Project, List<Task>) onCreate;

  const _ProjectPickerDialog({
    required this.projects,
    required this.tasks,
    required this.onCreate,
  });

  @override
  State<_ProjectPickerDialog> createState() => _ProjectPickerDialogState();
}

class _ProjectPickerDialogState extends State<_ProjectPickerDialog> {
  Project? _selected;

  List<Task> get _projectTasks =>
      widget.tasks.where((t) => t.projectId == _selected?.id).toList();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl),
          border: Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _T.blue50,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _T.blue.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 15,
                      color: _T.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Quotation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                            letterSpacing: -0.1,
                          ),
                        ),
                        Text(
                          'Select the project to quote for',
                          style: TextStyle(fontSize: 11.5, color: _T.slate400),
                        ),
                      ],
                    ),
                  ),
                  _DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Divider(height: 1, color: _T.slate100),
            ),

            // Project list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                itemCount: widget.projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final p = widget.projects[i];
                  final sel = _selected?.id == p.id;
                  final taskCount =
                      widget.tasks.where((t) => t.projectId == p.id).length;
                  return _ProjectPickerRow(
                    project: p,
                    taskCount: taskCount,
                    selected: sel,
                    onTap: () => setState(() => _selected = p),
                  );
                },
              ),
            ),

            // Task preview when project selected
            if (_selected != null && _projectTasks.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Divider(height: 1, color: _T.slate100),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_projectTasks.length} task${_projectTasks.length == 1 ? '' : 's'} '
                      'will be pre-filled as line items',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _T.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._projectTasks
                        .take(3)
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: _T.slate300,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _T.slate500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (_projectTasks.length > 3)
                      Text(
                        '+ ${_projectTasks.length - 3} more',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _T.slate400,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _GhostBtn(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _PrimaryBtn(
                      label: 'Create Quotation',
                      icon: Icons.add_rounded,
                      enabled: _selected != null,
                      onTap:
                          _selected == null
                              ? () {}
                              : () =>
                                  widget.onCreate(_selected!, _projectTasks),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectPickerRow extends StatefulWidget {
  final Project project;
  final int taskCount;
  final bool selected;
  final VoidCallback onTap;

  const _ProjectPickerRow({
    required this.project,
    required this.taskCount,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ProjectPickerRow> createState() => _ProjectPickerRowState();
}

class _ProjectPickerRowState extends State<_ProjectPickerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                widget.selected
                    ? _T.blue50
                    : _hovered
                    ? _T.slate50
                    : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: widget.selected ? _T.blue.withOpacity(0.4) : _T.slate200,
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.project.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.project.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.selected ? _T.ink : _T.ink3,
                  ),
                ),
              ),
              Text(
                '${widget.taskCount} task${widget.taskCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 11, color: _T.slate400),
              ),
              if (widget.selected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: _T.blue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNTS LIST PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _AccountsListPanel extends StatelessWidget {
  final TabController tabController;
  final List<Quotation> quotations;
  final List<Invoice> invoices;
  final List<Project> projects;
  final String? selectedQuotId;
  final String? selectedInvoiceId;
  final ValueChanged<Quotation> onSelectQuotation;
  final ValueChanged<Invoice> onSelectInvoice;

  const _AccountsListPanel({
    required this.tabController,
    required this.quotations,
    required this.invoices,
    required this.projects,
    required this.selectedQuotId,
    required this.selectedInvoiceId,
    required this.onSelectQuotation,
    required this.onSelectInvoice,
  });

  Project? _proj(String id) => projects.cast<Project?>().firstWhere(
    (p) => p!.id == id,
    orElse: () => null,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(right: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate100)),
            ),
            child: TabBar(
              controller: tabController,
              labelColor: _T.ink2,
              unselectedLabelColor: _T.slate400,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              indicatorColor: _T.blue,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Quotations'),
                      if (quotations.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(quotations.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Invoices'),
                      if (invoices.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(invoices.length),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                // Quotations list
                quotations.isEmpty
                    ? _EmptyListPane(
                      icon: Icons.receipt_long_outlined,
                      label: 'No quotations yet',
                      sublabel: 'Click "New Quotation" to get started',
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: quotations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final q = quotations[i];
                        return _QuotationListRow(
                          quotation: q,
                          project: _proj(q.projectId),
                          selected: selectedQuotId == q.id,
                          onTap: () => onSelectQuotation(q),
                        );
                      },
                    ),

                // Invoices list
                invoices.isEmpty
                    ? _EmptyListPane(
                      icon: Icons.summarize_outlined,
                      label: 'No invoices yet',
                      sublabel: 'Create an invoice from a quotation',
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final inv = invoices[i];
                        return _InvoiceListRow(
                          invoice: inv,
                          project: _proj(inv.projectId),
                          selected: selectedInvoiceId == inv.id,
                          onTap: () => onSelectInvoice(inv),
                        );
                      },
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotationListRow extends StatefulWidget {
  final Quotation quotation;
  final Project? project;
  final bool selected;
  final VoidCallback onTap;

  const _QuotationListRow({
    required this.quotation,
    required this.project,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_QuotationListRow> createState() => _QuotationListRowState();
}

class _QuotationListRowState extends State<_QuotationListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quotation;
    final sel = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                sel
                    ? _T.blue50
                    : _hovered
                    ? _T.slate50
                    : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: sel ? _T.blue.withOpacity(0.35) : _T.slate200,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: sel ? _T.blue.withOpacity(0.10) : _T.slate100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 13,
                  color: sel ? _T.blue : _T.slate500,
                ),
              ),
              const SizedBox(width: 10),

              // Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          q.number,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? _T.blue : _T.ink,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        _StatusPill(
                          label: q.status.label,
                          color: q.status.color,
                          bg: q.status.bg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (widget.project != null)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.project!.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.project!.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _T.slate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _fmtCurrency(q.total),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _T.ink3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _fmtDate(q.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceListRow extends StatefulWidget {
  final Invoice invoice;
  final Project? project;
  final bool selected;
  final VoidCallback onTap;

  const _InvoiceListRow({
    required this.invoice,
    required this.project,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InvoiceListRow> createState() => _InvoiceListRowState();
}

class _InvoiceListRowState extends State<_InvoiceListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final sel = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                sel
                    ? _T.blue50
                    : _hovered
                    ? _T.slate50
                    : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: sel ? _T.blue.withOpacity(0.35) : _T.slate200,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: sel ? _T.blue.withOpacity(0.10) : _T.slate100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.summarize_outlined,
                  size: 13,
                  color: sel ? _T.blue : _T.slate500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          inv.number,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? _T.blue : _T.ink,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        if (inv.hasChanges)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _ChangedBadge(),
                          ),
                        _StatusPill(
                          label: inv.status.label,
                          color: inv.status.color,
                          bg: inv.status.bg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (widget.project != null)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.project!.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.project!.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _T.slate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _fmtCurrency(inv.total),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _T.ink3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _fmtDate(inv.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUOTATION DETAIL — editable line-items table
// ─────────────────────────────────────────────────────────────────────────────
class _QuotationDetail extends StatefulWidget {
  final Quotation quotation;
  final Project? project;
  final List<Task> projectTasks;
  final bool hasInvoice;
  final ValueChanged<Quotation> onUpdate;
  final VoidCallback onCreateInvoice;
  final VoidCallback onClose;

  const _QuotationDetail({
    super.key,
    required this.quotation,
    required this.project,
    required this.projectTasks,
    required this.hasInvoice,
    required this.onUpdate,
    required this.onCreateInvoice,
    required this.onClose,
  });

  @override
  State<_QuotationDetail> createState() => _QuotationDetailState();
}

class _QuotationDetailState extends State<_QuotationDetail> {
  late Quotation _q;

  @override
  void initState() {
    super.initState();
    _q = widget.quotation;
  }

  void _addBlankLine() {
    setState(() {
      _q.lineItems.add(
        QuotationLineItem(
          id: 'q_manual_${DateTime.now().millisecondsSinceEpoch}',
          description: '',
          qty: 1,
          unitPrice: 0,
        ),
      );
    });
    widget.onUpdate(_q);
  }

  void _removeLine(int i) {
    setState(() => _q.lineItems.removeAt(i));
    widget.onUpdate(_q);
  }

  void _updateLine(int i, QuotationLineItem updated) {
    setState(() => _q.lineItems[i] = updated);
    widget.onUpdate(_q);
  }

  void _setStatus(QuotationStatus s) {
    setState(() => _q.status = s);
    widget.onUpdate(_q);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Detail topbar ──────────────────────────────────────────────
          _DetailTopbar(
            number: _q.number,
            icon: Icons.receipt_long_outlined,
            iconColor: _T.blue,
            iconBg: _T.blue50,
            subtitle: widget.project?.name ?? '',
            onClose: widget.onClose,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status picker
                _StatusDropdown<QuotationStatus>(
                  current: _q.status,
                  values: QuotationStatus.values,
                  label: (s) => s.label,
                  color: (s) => s.color,
                  bg: (s) => s.bg,
                  onChanged: _setStatus,
                ),
                const SizedBox(width: 8),
                // Create Invoice CTA
                if (!widget.hasInvoice)
                  _PrimaryBtn(
                    label: 'Create Invoice',
                    icon: Icons.summarize_outlined,
                    enabled: _q.total > 0,
                    onTap: widget.onCreateInvoice,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _T.green50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _T.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 11, color: _T.green),
                        SizedBox(width: 5),
                        Text(
                          'Invoice created',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _T.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document header card
                  _DocumentHeaderCard(
                    number: _q.number,
                    project: widget.project,
                    date: _q.createdAt,
                    label: 'QUOTATION',
                    color: _T.blue,
                    bg: _T.blue50,
                  ),
                  const SizedBox(height: 20),

                  // Line items table
                  _LineItemsTable(
                    items: _q.lineItems,
                    editable: true,
                    onUpdate: _updateLine,
                    onRemove: _removeLine,
                    onAddLine: _addBlankLine,
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  _NotesField(
                    value: _q.notes,
                    onChanged: (v) {
                      setState(() => _q.notes = v);
                      widget.onUpdate(_q);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Footer total bar ───────────────────────────────────────────
          _TotalFooter(total: _q.total),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INVOICE DETAIL — read-mostly + diff highlights
// ─────────────────────────────────────────────────────────────────────────────
class _InvoiceDetail extends StatefulWidget {
  final Invoice invoice;
  final Project? project;
  final Quotation? sourceQuotation;
  final ValueChanged<Invoice> onUpdate;
  final VoidCallback onClose;

  const _InvoiceDetail({
    super.key,
    required this.invoice,
    required this.project,
    required this.sourceQuotation,
    required this.onUpdate,
    required this.onClose,
  });

  @override
  State<_InvoiceDetail> createState() => _InvoiceDetailState();
}

class _InvoiceDetailState extends State<_InvoiceDetail> {
  late Invoice _inv;

  @override
  void initState() {
    super.initState();
    _inv = widget.invoice;
  }

  void _setStatus(InvoiceStatus s) {
    setState(() => _inv.status = s);
    widget.onUpdate(_inv);
  }

  void _updateLine(int i, InvoiceLineItem updated) {
    setState(() => _inv.lineItems[i] = updated);
    widget.onUpdate(_inv);
  }

  void _removeLine(int i) {
    setState(() => _inv.lineItems.removeAt(i));
    widget.onUpdate(_inv);
  }

  void _addBlankLine() {
    setState(() {
      _inv.lineItems.add(
        InvoiceLineItem(
          id: 'inv_manual_${DateTime.now().millisecondsSinceEpoch}',
          description: '',
          qty: 1,
          unitPrice: 0,
          originalDescription: '',
          originalQty: 1,
          originalUnitPrice: 0,
        ),
      );
    });
    widget.onUpdate(_inv);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Detail topbar ──────────────────────────────────────────────
          _DetailTopbar(
            number: _inv.number,
            icon: Icons.summarize_outlined,
            iconColor: _T.purple,
            iconBg: _T.purple50,
            subtitle: widget.project?.name ?? '',
            onClose: widget.onClose,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusDropdown<InvoiceStatus>(
                  current: _inv.status,
                  values: InvoiceStatus.values,
                  label: (s) => s.label,
                  color: (s) => s.color,
                  bg: (s) => s.bg,
                  onChanged: _setStatus,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DocumentHeaderCard(
                    number: _inv.number,
                    project: widget.project,
                    date: _inv.createdAt,
                    label: 'INVOICE',
                    color: _T.purple,
                    bg: _T.purple50,
                    extra:
                        _inv.dueDate != null
                            ? 'Due ${_fmtDate(_inv.dueDate!)}'
                            : null,
                  ),
                  const SizedBox(height: 12),

                  // Quotation reference chip
                  if (widget.sourceQuotation != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link_rounded,
                            size: 12,
                            color: _T.slate400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Created from ',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _T.slate400,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _T.blue50,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _T.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              widget.sourceQuotation!.number,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _T.blue,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Changes banner — shown only when invoice differs from quot
                  if (_inv.hasChanges) _ChangesBanner(invoice: _inv),

                  const SizedBox(height: 4),

                  // Invoice line items — editable, with diff highlights
                  _InvoiceLineItemsTable(
                    items: _inv.lineItems,
                    onUpdate: _updateLine,
                    onRemove: _removeLine,
                    onAddLine: _addBlankLine,
                  ),
                  const SizedBox(height: 16),

                  _NotesField(
                    value: _inv.notes,
                    onChanged: (v) {
                      setState(() => _inv.notes = v);
                      widget.onUpdate(_inv);
                    },
                  ),
                ],
              ),
            ),
          ),

          _TotalFooter(
            total: _inv.total,
            delta: _inv.hasChanges ? _inv.totalDelta : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANGES BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _ChangesBanner extends StatefulWidget {
  final Invoice invoice;
  const _ChangesBanner({required this.invoice});

  @override
  State<_ChangesBanner> createState() => _ChangesBannerState();
}

class _ChangesBannerState extends State<_ChangesBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final changedItems =
        widget.invoice.lineItems.where((i) => i.hasAnyChange).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.amber.withOpacity(0.35)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: _T.amber.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_T.rLg),
                  bottomLeft: Radius.circular(_T.rLg),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 13,
                          color: _T.amber.withOpacity(0.9),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${changedItems.length} line item${changedItems.length == 1 ? '' : 's'} '
                          'modified from quotation',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _T.amber.withOpacity(0.9),
                          ),
                        ),
                        const Spacer(),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Text(
                              _expanded ? 'Hide' : 'See changes',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _T.amber.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Expanded diff list
                    if (_expanded) ...[
                      const SizedBox(height: 10),
                      ...changedItems.map((item) => _DiffRow(item: item)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final InvoiceLineItem item;
  const _DiffRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            item.description.isNotEmpty
                ? item.description
                : item.originalDescription,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _T.ink3,
            ),
          ),
          const SizedBox(height: 4),

          // Changed fields
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (item.descriptionChanged)
                _DiffChip(
                  label: 'Description',
                  from: item.originalDescription,
                  to: item.description,
                ),
              if (item.qtyChanged)
                _DiffChip(
                  label: 'Qty',
                  from: _fmtNum(item.originalQty),
                  to: _fmtNum(item.qty),
                ),
              if (item.unitPriceChanged)
                _DiffChip(
                  label: 'Unit price',
                  from: _fmtCurrency(item.originalUnitPrice),
                  to: _fmtCurrency(item.unitPrice),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  final String label, from, to;
  const _DiffChip({required this.label, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _T.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10.5, color: _T.slate500),
          ),
          Text(
            from,
            style: const TextStyle(
              fontSize: 10.5,
              color: _T.red,
              decoration: TextDecoration.lineThrough,
              decorationColor: _T.red,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 9,
              color: _T.slate400,
            ),
          ),
          Text(
            to,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: _T.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LINE ITEMS TABLE — quotation (editable)
// ─────────────────────────────────────────────────────────────────────────────
class _LineItemsTable extends StatelessWidget {
  final List<QuotationLineItem> items;
  final bool editable;
  final void Function(int, QuotationLineItem) onUpdate;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddLine;

  const _LineItemsTable({
    required this.items,
    required this.editable,
    required this.onUpdate,
    required this.onRemove,
    required this.onAddLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: _T.slate50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_T.rLg),
                topRight: Radius.circular(_T.rLg),
              ),
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 5, child: _TblHdr('DESCRIPTION')),
                const Expanded(flex: 2, child: _TblHdr('QTY')),
                const Expanded(flex: 2, child: _TblHdr('UNIT PRICE')),
                const Expanded(flex: 2, child: _TblHdr('AMOUNT')),
                if (editable) const SizedBox(width: 32),
              ],
            ),
          ),

          // Rows
          ...items.asMap().entries.map(
            (e) => _LineItemRow(
              item: e.value,
              index: e.key,
              isLast: e.key == items.length - 1,
              editable: editable,
              onUpdate: (updated) => onUpdate(e.key, updated),
              onRemove: () => onRemove(e.key),
            ),
          ),

          // Add line button
          if (editable) _AddLineButton(onTap: onAddLine),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatefulWidget {
  final QuotationLineItem item;
  final int index;
  final bool isLast;
  final bool editable;
  final ValueChanged<QuotationLineItem> onUpdate;
  final VoidCallback onRemove;

  const _LineItemRow({
    required this.item,
    required this.index,
    required this.isLast,
    required this.editable,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<_LineItemRow> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.description);
    _qtyCtrl = TextEditingController(text: _fmtNum(widget.item.qty));
    _priceCtrl = TextEditingController(text: _fmtNum(widget.item.unitPrice));

    for (final c in [_descCtrl, _qtyCtrl, _priceCtrl]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() {
    widget.onUpdate(
      widget.item.copyWith(
        description: _descCtrl.text,
        qty: double.tryParse(_qtyCtrl.text) ?? widget.item.qty,
        unitPrice: double.tryParse(_priceCtrl.text) ?? widget.item.unitPrice,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _qtyCtrl, _priceCtrl]) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount =
        (double.tryParse(_qtyCtrl.text) ?? 0) *
        (double.tryParse(_priceCtrl.text) ?? 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: _hovered ? _T.slate50 : _T.white,
          border:
              widget.isLast
                  ? null
                  : const Border(bottom: BorderSide(color: _T.slate100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Description
            Expanded(
              flex: 5,
              child:
                  widget.editable
                      ? _InlineTextField(
                        controller: _descCtrl,
                        hint: 'Item description',
                      )
                      : Text(
                        widget.item.description,
                        style: const TextStyle(fontSize: 13, color: _T.ink3),
                      ),
            ),

            // Qty
            Expanded(
              flex: 2,
              child:
                  widget.editable
                      ? _InlineNumField(controller: _qtyCtrl, hint: '0')
                      : Text(
                        _fmtNum(widget.item.qty),
                        style: const TextStyle(fontSize: 13, color: _T.ink3),
                      ),
            ),

            // Unit price
            Expanded(
              flex: 2,
              child:
                  widget.editable
                      ? _InlineNumField(
                        controller: _priceCtrl,
                        hint: '0.00',
                        prefix: '\$',
                      )
                      : Text(
                        _fmtCurrency(widget.item.unitPrice),
                        style: const TextStyle(fontSize: 13, color: _T.ink3),
                      ),
            ),

            // Amount
            Expanded(
              flex: 2,
              child: Text(
                _fmtCurrency(amount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: amount > 0 ? _T.ink : _T.slate300,
                ),
              ),
            ),

            // Remove
            if (widget.editable)
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 100),
                child: _RemoveLineButton(onTap: widget.onRemove),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INVOICE LINE ITEMS TABLE — editable with diff highlights per cell
// ─────────────────────────────────────────────────────────────────────────────
class _InvoiceLineItemsTable extends StatelessWidget {
  final List<InvoiceLineItem> items;
  final void Function(int, InvoiceLineItem) onUpdate;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddLine;

  const _InvoiceLineItemsTable({
    required this.items,
    required this.onUpdate,
    required this.onRemove,
    required this.onAddLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: _T.slate50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_T.rLg),
                topRight: Radius.circular(_T.rLg),
              ),
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 5, child: _TblHdr('DESCRIPTION')),
                const Expanded(flex: 2, child: _TblHdr('QTY')),
                const Expanded(flex: 2, child: _TblHdr('UNIT PRICE')),
                const Expanded(flex: 2, child: _TblHdr('AMOUNT')),
                const SizedBox(width: 32),
              ],
            ),
          ),

          ...items.asMap().entries.map(
            (e) => _InvoiceLineItemRow(
              item: e.value,
              isLast: e.key == items.length - 1,
              onUpdate: (updated) => onUpdate(e.key, updated),
              onRemove: () => onRemove(e.key),
            ),
          ),

          _AddLineButton(onTap: onAddLine),
        ],
      ),
    );
  }
}

class _InvoiceLineItemRow extends StatefulWidget {
  final InvoiceLineItem item;
  final bool isLast;
  final ValueChanged<InvoiceLineItem> onUpdate;
  final VoidCallback onRemove;

  const _InvoiceLineItemRow({
    required this.item,
    required this.isLast,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_InvoiceLineItemRow> createState() => _InvoiceLineItemRowState();
}

class _InvoiceLineItemRowState extends State<_InvoiceLineItemRow> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.description);
    _qtyCtrl = TextEditingController(text: _fmtNum(widget.item.qty));
    _priceCtrl = TextEditingController(text: _fmtNum(widget.item.unitPrice));
    for (final c in [_descCtrl, _qtyCtrl, _priceCtrl]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() {
    final newQty = double.tryParse(_qtyCtrl.text) ?? widget.item.qty;
    final newPrice = double.tryParse(_priceCtrl.text) ?? widget.item.unitPrice;
    widget.onUpdate(
      InvoiceLineItem(
        id: widget.item.id,
        taskId: widget.item.taskId,
        description: _descCtrl.text,
        qty: newQty,
        unitPrice: newPrice,
        originalDescription: widget.item.originalDescription,
        originalQty: widget.item.originalQty,
        originalUnitPrice: widget.item.originalUnitPrice,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _qtyCtrl, _priceCtrl]) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final amount =
        (double.tryParse(_qtyCtrl.text) ?? 0) *
        (double.tryParse(_priceCtrl.text) ?? 0);

    // Row gets a very subtle amber tint if any cell changed
    final rowBg =
        item.hasAnyChange
            ? (_hovered ? const Color(0xFFFEF9C3) : const Color(0xFFFFFDE7))
            : (_hovered ? _T.slate50 : _T.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: rowBg,
          border:
              widget.isLast
                  ? null
                  : const Border(bottom: BorderSide(color: _T.slate100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: _ChangedCell(
                changed: item.descriptionChanged,
                originalText: item.originalDescription,
                child: _InlineTextField(
                  controller: _descCtrl,
                  hint: 'Item description',
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: _ChangedCell(
                changed: item.qtyChanged,
                originalText: _fmtNum(item.originalQty),
                child: _InlineNumField(controller: _qtyCtrl, hint: '0'),
              ),
            ),

            Expanded(
              flex: 2,
              child: _ChangedCell(
                changed: item.unitPriceChanged,
                originalText: _fmtCurrency(item.originalUnitPrice),
                child: _InlineNumField(
                  controller: _priceCtrl,
                  hint: '0.00',
                  prefix: '\$',
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                _fmtCurrency(amount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: amount > 0 ? _T.ink : _T.slate300,
                ),
              ),
            ),

            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: _RemoveLineButton(onTap: widget.onRemove),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANGED CELL — wraps a field with a tooltip showing the original value
// ─────────────────────────────────────────────────────────────────────────────
class _ChangedCell extends StatelessWidget {
  final bool changed;
  final String originalText;
  final Widget child;

  const _ChangedCell({
    required this.changed,
    required this.originalText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!changed) return child;

    return Tooltip(
      message: 'Was: $originalText',
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: _T.ink,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(fontSize: 11.5, color: Colors.white),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          // Small amber dot in top-right corner signals change
          Positioned(
            top: 0,
            right: 2,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: _T.amber,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED DETAIL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DetailTopbar extends StatelessWidget {
  final String number;
  final IconData icon;
  final Color iconColor, iconBg;
  final String subtitle;
  final VoidCallback onClose;
  final Widget trailing;

  const _DetailTopbar({
    required this.number,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.subtitle,
    required this.onClose,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CloseBtn(onTap: onClose),
          const SizedBox(width: 14),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _T.ink,
                  fontFamily: 'monospace',
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: _T.slate400),
                ),
            ],
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class _DocumentHeaderCard extends StatelessWidget {
  final String number;
  final Project? project;
  final DateTime date;
  final String label;
  final Color color, bg;
  final String? extra;

  const _DocumentHeaderCard({
    required this.number,
    required this.project,
    required this.date,
    required this.label,
    required this.color,
    required this.bg,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: number + project
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _T.ink,
                    letterSpacing: -0.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 6),
                if (project != null)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: project!.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        project!.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _T.ink3,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Right: date + extra
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'DATE',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _T.slate400,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _fmtDate(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _T.ink3,
                ),
              ),
              if (extra != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _T.amber50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _T.amber.withOpacity(0.3)),
                  ),
                  child: Text(
                    extra!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _T.amber,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _NotesField({required this.value, required this.onChanged});

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _ctrl;
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    _ctrl.addListener(() => widget.onChanged(_ctrl.text));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOTES',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _focused ? _T.white : _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: _focused ? _T.blue : _T.slate200,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontSize: 13, color: _T.ink3, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Add notes, payment terms, or conditions…',
              hintStyle: TextStyle(fontSize: 13, color: _T.slate300),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalFooter extends StatelessWidget {
  final double total;
  final double? delta;

  const _TotalFooter({required this.total, this.delta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(top: BorderSide(color: _T.slate100)),
      ),
      child: Row(
        children: [
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _T.slate400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _fmtCurrency(total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _T.ink,
                  letterSpacing: -0.5,
                ),
              ),
              if (delta != null && delta != 0) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      delta! > 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 11,
                      color: delta! > 0 ? _T.amber : _T.green,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${delta! > 0 ? '+' : ''}${_fmtCurrency(delta!)} '
                      'from quotation',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: delta! > 0 ? _T.amber : _T.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────
class _StatusDropdown<T> extends StatelessWidget {
  final T current;
  final List<T> values;
  final String Function(T) label;
  final Color Function(T) color;
  final Color Function(T) bg;
  final ValueChanged<T> onChanged;

  const _StatusDropdown({
    required this.current,
    required this.values,
    required this.label,
    required this.color,
    required this.bg,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_T.rLg),
        side: const BorderSide(color: _T.slate200),
      ),
      color: _T.white,
      elevation: 4,
      onSelected: onChanged,
      itemBuilder:
          (_) =>
              values
                  .map(
                    (v) => PopupMenuItem<T>(
                      value: v,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color(v),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label(v),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  v == current
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                              color: v == current ? color(v) : _T.ink3,
                            ),
                          ),
                          if (v == current) ...[
                            const Spacer(),
                            Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: color(v),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg(current),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color(current).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color(current),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label(current),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color(current),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 13,
              color: color(current),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE TEXT / NUM FIELDS for line item table cells
// ─────────────────────────────────────────────────────────────────────────────
class _InlineTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const _InlineTextField({required this.controller, required this.hint});

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: _focused ? _T.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _focused ? _T.blue : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        style: const TextStyle(fontSize: 13, color: _T.ink3),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
        ),
      ),
    );
  }
}

class _InlineNumField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefix;

  const _InlineNumField({
    required this.controller,
    required this.hint,
    this.prefix,
  });

  @override
  State<_InlineNumField> createState() => _InlineNumFieldState();
}

class _InlineNumFieldState extends State<_InlineNumField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: _focused ? _T.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _focused ? _T.blue : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.prefix != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                widget.prefix!,
                style: const TextStyle(fontSize: 12, color: _T.slate400),
              ),
            ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(fontSize: 13, color: _T.ink3),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
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
// SMALL SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _AddLineButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddLineButton({required this.onTap});

  @override
  State<_AddLineButton> createState() => _AddLineButtonState();
}

class _AddLineButtonState extends State<_AddLineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _T.slate50 : _T.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(_T.rLg),
              bottomRight: Radius.circular(_T.rLg),
            ),
            border: const Border(top: BorderSide(color: _T.slate100)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                size: 13,
                color: _hovered ? _T.blue : _T.slate400,
              ),
              const SizedBox(width: 6),
              Text(
                'Add line item',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? _T.blue : _T.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveLineButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RemoveLineButton({required this.onTap});

  @override
  State<_RemoveLineButton> createState() => _RemoveLineButtonState();
}

class _RemoveLineButtonState extends State<_RemoveLineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: _hovered ? _T.red50 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: _hovered ? _T.red : _T.slate300,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseBtn({required this.onTap});

  @override
  State<_CloseBtn> createState() => _CloseBtnState();
}

class _CloseBtnState extends State<_CloseBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _hovered ? _T.slate100 : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _T.slate200),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 13,
          color: _hovered ? _T.ink3 : _T.slate400,
        ),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _StatusPill({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _ChangedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: _T.amber50,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _T.amber.withOpacity(0.3)),
    ),
    child: const Text(
      'Modified',
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: _T.amber,
      ),
    ),
  );
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: _T.slate100,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _T.slate500,
      ),
    ),
  );
}

class _TblHdr extends StatelessWidget {
  final String text;
  const _TblHdr(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: _T.slate400,
    ),
  );
}

class _EmptyListPane extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  const _EmptyListPane({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _T.slate400),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sublabel,
          style: const TextStyle(fontSize: 11.5, color: _T.slate300),
        ),
      ],
    ),
  );
}

class _AccountsIdlePane extends StatelessWidget {
  const _AccountsIdlePane();

  @override
  Widget build(BuildContext context) => Container(
    color: _T.slate50,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _T.slate200),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Select a quotation or invoice',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'or click "New Quotation" to create one',
            style: TextStyle(fontSize: 12, color: _T.slate300),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BUTTON PRIMITIVES
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg =
        widget.enabled ? (_hovered ? _T.blueHover : _T.blue) : _T.slate100;

    return MouseRegion(
      cursor:
          widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: widget.enabled ? Colors.white : _T.slate400,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled ? Colors.white : _T.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _GhostBtn({required this.label, this.onTap});

  @override
  State<_GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<_GhostBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _T.slate100 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _T.slate200),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _T.slate500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DialogCloseButton({required this.onTap});

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _hovered ? _T.slate100 : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _T.slate200),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 13,
          color: _hovered ? _T.ink3 : _T.slate400,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fmtCurrency(double v) {
  if (v == 0) return '\$0.00';
  return '\$${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
}

String _fmtNum(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
