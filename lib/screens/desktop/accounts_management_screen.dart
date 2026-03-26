// ─────────────────────────────────────────────────────────────────────────────
// accounts_management_screen.dart
//
// Cleaned up — BillingDocumentView is the single document renderer.
// _QuotationDetail and _InvoiceDetail now own editable line-item state
// and expose an Edit / Preview mode toggle.
//
// EDIT MODE  — BillingEditView: mirrors the document layout with tappable
//              cells for description, qty, unit price. Feels like editing
//              the document itself, not a separate form.
//
// PREVIEW MODE — BillingDocumentView: the original final-product view,
//                passed the current line-item state.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/connection_status_banner.dart';
import 'package:smooflow/core/api/websocket_clients/pricing_websocket.dart';
import 'package:smooflow/core/models/company.dart';
import 'package:smooflow/core/models/pricing.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/providers/company_provider.dart';
import 'package:smooflow/providers/pricing_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/accounts/pricing/components.dart';
import 'package:smooflow/screens/desktop/components/action_buttons.dart';
import 'package:smooflow/screens/desktop/components/billing_document_view.dart';
import 'package:smooflow/screens/desktop/components/close_btn.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';
import 'package:smooflow/screens/desktop/helpers/accounts_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue50 = Color(0xFFEFF6FF);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
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

class Quotation {
  final String id;
  final String projectId;
  List<QuotationLineItem> lineItems;
  QuotationStatus status;
  String notes;
  final DateTime createdAt;
  final String number;
  double vatPercentage;

  double get total => lineItems.fold(0, (s, i) => s + i.amount);

  Quotation({
    required this.id,
    required this.projectId,
    required this.lineItems,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.number,
    this.vatPercentage = 5.0,
  });
}

class Invoice {
  final String id;
  final String quotationId;
  final String projectId;
  List<QuotationLineItem> lineItems; // reuses QuotationLineItem — same shape
  InvoiceStatus status;
  String notes;
  DateTime? dueDate;
  final DateTime createdAt;
  final String number;
  double vatPercentage;

  double get total => lineItems.fold(0, (s, i) => s + i.amount);

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
    this.vatPercentage = 5.0,
  });

  factory Invoice.fromQuotation(Quotation q, String number) => Invoice(
    id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
    quotationId: q.id,
    projectId: q.projectId,
    lineItems:
        q.lineItems
            .map(
              (i) => QuotationLineItem(
                id: '${i.id}',
                taskId: i.taskId,
                description: i.description,
                subTitle: i.subTitle,
                qty: i.qty,
                unitPrice: i.unitPrice,
              ),
            )
            .toList(),
    status: InvoiceStatus.draft,
    notes: q.notes,
    dueDate: DateTime.now().add(const Duration(days: 30)),
    createdAt: DateTime.now(),
    number: number,
    vatPercentage: q.vatPercentage,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW MODE
// ─────────────────────────────────────────────────────────────────────────────
enum _DocMode { edit, preview }

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AccountsManagementScreen extends ConsumerStatefulWidget {
  const AccountsManagementScreen({super.key});

  @override
  ConsumerState<AccountsManagementScreen> createState() =>
      _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsManagementScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;

  // Add these new variables
  late final TabController
  _mainTabController; // For switching between docs and pricing
  Pricing? _selectedPricing;
  Company? _selectedClientForPricing;
  bool _showPricingDetail = false;
  bool _isCreatingPricing = false;

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
    _mainTabController = TabController(length: 2, vsync: this); // NEW
    _tab.addListener(() => setState(() {}));
    _mainTabController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pricingStateProvider.notifier).fetchPricing();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  // ... existing methods ...

  // NEW: Methods for pricing management
  void _createPricing() {
    setState(() {
      _selectedPricing = null;
      _showPricingDetail = true;
      _isCreatingPricing = true;
    });
  }

  void _selectPricing(Pricing pricing) {
    setState(() {
      _selectedPricing = pricing;
      _showPricingDetail = true;
      _isCreatingPricing = false;
    });
  }

  void _closePricingDetail() {
    setState(() {
      _selectedPricing = null;
      _showPricingDetail = false;
      _isCreatingPricing = false;
    });
  }

  void _updatePricing(Pricing pricing) {
    setState(() {
      _selectedPricing = pricing;
    });
  }

  void _createQuotation(Project project, List<Task> tasks) {
    int idx = 1;
    final lineItems =
        tasks
            .map(
              (t) => QuotationLineItem(
                id: (idx++).toString(),
                taskId: t.id,
                description: t.ref ?? t.name,
                subTitle: [
                  if (t.size != null) 'Size: ${t.size}',
                  'with Installation at site',
                ].join(' '),
                qty: (t.productionQuantity ?? t.quantity ?? 1).toDouble(),
                unitPrice: 0,
              ),
            )
            .toList();

    if (lineItems.isEmpty) {
      lineItems.add(
        QuotationLineItem(id: '1', description: '', qty: 1, unitPrice: 0),
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
    final i = _quotations.indexWhere((x) => x.id == q.id);
    if (i != -1) _quotations[i] = q;
    _selectedQuotation = q;
  });

  void _updateInvoice(Invoice inv) => setState(() {
    final i = _invoices.indexWhere((x) => x.id == inv.id);
    if (i != -1) _invoices[i] = inv;
    _selectedInvoice = inv;
  });

  void _showChangeNotification(BuildContext context, PricingChangeEvent event) {
    String message;
    IconData icon;
    Color color;

    switch (event.type) {
      case PricingChangeType.created:
        message = 'New Pricing Added';
        icon = Icons.price_change_outlined;
        color = _T.green;
        break;
      case PricingChangeType.updated:
        message = 'Pricing updated';
        icon = Icons.update;
        color = _T.blue;
        break;
      case PricingChangeType.deleted:
        message = 'Pricing ${event.pricing.description} removed';
        icon = Icons.person_remove;
        color = _T.red;
        break;
    }

    AppToast.show(
      message: message,
      icon: icon,
      color: color,
      subtitle: event.pricing.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectNotifierProvider);
    final tasks = ref.watch(taskNotifierProvider).tasks;
    final pricingList = ref.watch(pricingStateProvider).pricingData;
    final companies = ref.watch(companyListProvider).companies;

    // Listen for real-time changes
    ref.listen<AsyncValue<PricingChangeEvent>>(pricingChangesStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((event) {
        _showChangeNotification(context, event);
      });
    });

    // Determine what to show in the right panel
    final Widget detail;
    if (_mainTabController.index == 1) {
      // Pricing tab
      if (_showPricingDetail) {
        if (_isCreatingPricing) {
          // Show create form instead of idle pane
          detail = CreatePricingPanel(
            companies: companies,
            onCreate: (pricing) async {
              try {
                final created = await ref
                    .read(pricingStateProvider.notifier)
                    .createPricing(pricing);
                _selectPricing(created); // Select the newly created pricing
              } catch (e) {
                rethrow;
              }
            },
            onCancel: _closePricingDetail,
          );
        } else if (_selectedPricing != null) {
          detail = PricingDetailPanel(
            key: ValueKey(_selectedPricing!.id),
            pricing: _selectedPricing!,
            companies: companies,
            onUpdate: (updated) {
              ref.read(pricingStateProvider.notifier).updatePricing(updated);
              _updatePricing(updated);
            },
            onClose: _closePricingDetail,
          );
        } else {
          detail = PricingIdlePane(onCreate: _createPricing);
        }
      } else {
        detail = PricingIdlePane(onCreate: _createPricing);
      }
    } else {
      // Documents tab (existing logic)
      if (_showingInvoice && _selectedInvoice != null) {
        final proj = projects.cast<Project?>().firstWhere(
          (p) => p?.id == _selectedInvoice!.projectId,
          orElse: () => null,
        );
        detail = _InvoiceDetail(
          key: ValueKey(_selectedInvoice!.id),
          invoice: _selectedInvoice!,
          project: proj,
          onUpdate: _updateInvoice,
          onClose:
              () => setState(() {
                _selectedInvoice = null;
                _showingInvoice = false;
              }),
        );
      } else if (!_showingInvoice && _selectedQuotation != null) {
        final proj = projects.cast<Project?>().firstWhere(
          (p) => p?.id == _selectedQuotation!.projectId,
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
          onCreateInvoice:
              () => _createInvoiceFromQuotation(_selectedQuotation!),
          onClose: () => setState(() => _selectedQuotation = null),
        );
      } else {
        detail = const _AccountsIdlePane();
      }
    }

    return Scaffold(
      backgroundColor: _T.white,
      body: Column(
        children: [
          // Updated topbar with tab switcher
          _AccountsTopbarWithTabs(
            mainTabController: _mainTabController,
            projects: projects,
            tasks: tasks,
            onNewQuotation: _createQuotation,
            onNewPricing: _createPricing,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel - changes based on selected main tab
                SizedBox(
                  width: 315,
                  child:
                      _mainTabController.index == 0
                          ? _AccountsListPanel(
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
                          )
                          : PricingListPanel(
                            pricingList: pricingList,
                            selectedId: _selectedPricing?.id,
                            onSelect: _selectPricing,
                            onCreate: _createPricing,
                          ),
                ),
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
// NEW: Topbar with tabs for Documents / Price Lists
// ─────────────────────────────────────────────────────────────────────────────
class _AccountsTopbarWithTabs extends ConsumerWidget {
  final TabController mainTabController;
  final List<Project> projects;
  final List<Task> tasks;
  final void Function(Project, List<Task>) onNewQuotation;
  final VoidCallback onNewPricing;

  const _AccountsTopbarWithTabs({
    required this.mainTabController,
    required this.projects,
    required this.tasks,
    required this.onNewQuotation,
    required this.onNewPricing,
  });

  @override
  Widget build(BuildContext context, ref) {
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
          const SizedBox(width: 20),
          // Tab selector
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MainTabButton(
                  label: 'Documents',
                  index: 0,
                  controller: mainTabController,
                ),
                MainTabButton(
                  label: 'Price Lists',
                  index: 1,
                  controller: mainTabController,
                ),
              ],
            ),
          ),
          SizedBox(width: 15),
          const Spacer(),
          // Action button changes based on selected tab
          AnimatedBuilder(
            animation: mainTabController,
            builder: (context, _) {
              if (mainTabController.index == 0) {
                return _NewQuotationButton(
                  projects: projects,
                  tasks: tasks,
                  onCreate: onNewQuotation,
                );
              } else {
                return NewPricingButton(onTap: onNewPricing);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUOTATION DETAIL
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
  _DocMode _mode = _DocMode.edit;

  @override
  void initState() {
    super.initState();
    _q = widget.quotation;
  }

  void _onItemsChanged(List<QuotationLineItem> items) {
    setState(() => _q.lineItems = items);
    widget.onUpdate(_q);
  }

  void _setStatus(QuotationStatus s) {
    setState(() => _q.status = s);
    widget.onUpdate(_q);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Topbar ─────────────────────────────────────────────────────
        _DocTopbar(
          number: _q.number,
          subtitle: widget.project?.name ?? '',
          mode: _mode,
          onModeChanged: (m) => setState(() => _mode = m),
          onClose: widget.onClose,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusDropdown<QuotationStatus>(
                current: _q.status,
                values: QuotationStatus.values,
                label: (s) => s.label,
                color: (s) => s.color,
                bg: (s) => s.bg,
                onChanged: _setStatus,
              ),
              const SizedBox(width: 8),
              if (!widget.hasInvoice)
                _PrimaryBtn(
                  label: 'Create Invoice',
                  icon: Icons.summarize_outlined,
                  enabled: _q.total > 0,
                  onTap: widget.onCreateInvoice,
                )
              else
                _InvoiceCreatedChip(),
            ],
          ),
        ),

        // ── Body ───────────────────────────────────────────────────────
        Expanded(
          child:
              _mode == _DocMode.edit
                  ? BillingEditView(
                    lineItems: _q.lineItems,
                    vatPercentage: _q.vatPercentage,
                    docType: 'QUOTATION',
                    docNumber: _q.number,
                    docDate: _q.createdAt,
                    onChanged: _onItemsChanged,
                  )
                  : BillingDocumentView(
                    lineItems: _q.lineItems,
                    vatPercentage: _q.vatPercentage,
                  ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INVOICE DETAIL
// ─────────────────────────────────────────────────────────────────────────────
class _InvoiceDetail extends StatefulWidget {
  final Invoice invoice;
  final Project? project;
  final ValueChanged<Invoice> onUpdate;
  final VoidCallback onClose;

  const _InvoiceDetail({
    super.key,
    required this.invoice,
    required this.project,
    required this.onUpdate,
    required this.onClose,
  });

  @override
  State<_InvoiceDetail> createState() => _InvoiceDetailState();
}

class _InvoiceDetailState extends State<_InvoiceDetail> {
  late Invoice _inv;
  _DocMode _mode = _DocMode.edit;

  @override
  void initState() {
    super.initState();
    _inv = widget.invoice;
  }

  void _onItemsChanged(List<QuotationLineItem> items) {
    setState(() => _inv.lineItems = items);
    widget.onUpdate(_inv);
  }

  void _setStatus(InvoiceStatus s) {
    setState(() => _inv.status = s);
    widget.onUpdate(_inv);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocTopbar(
          number: _inv.number,
          subtitle: widget.project?.name ?? '',
          mode: _mode,
          onModeChanged: (m) => setState(() => _mode = m),
          onClose: widget.onClose,
          trailing: _StatusDropdown<InvoiceStatus>(
            current: _inv.status,
            values: InvoiceStatus.values,
            label: (s) => s.label,
            color: (s) => s.color,
            bg: (s) => s.bg,
            onChanged: _setStatus,
          ),
        ),

        Expanded(
          child:
              _mode == _DocMode.edit
                  ? BillingEditView(
                    lineItems: _inv.lineItems,
                    vatPercentage: _inv.vatPercentage,
                    docType: 'INVOICE',
                    docNumber: _inv.number,
                    docDate: _inv.createdAt,
                    dueDate: _inv.dueDate,
                    onChanged: _onItemsChanged,
                  )
                  : BillingDocumentView(
                    lineItems: _inv.lineItems,
                    vatPercentage: _inv.vatPercentage,
                  ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING EDIT VIEW
//
// Mirrors the visual structure of BillingDocumentView exactly so the
// accountant feels like they're editing the document itself, not a separate
// form. Each editable cell (description, qty, rate) is tappable — tapping
// activates an inline text field that replaces the static text. Clicking
// away or pressing Tab/Enter commits the value.
//
// Non-editable elements (logo zone, company address, client info, totals)
// are rendered identically to BillingDocumentView, except totals update
// live as values change.
// ─────────────────────────────────────────────────────────────────────────────
class BillingEditView extends StatefulWidget {
  final List<QuotationLineItem> lineItems;
  final double vatPercentage;
  final String docType;
  final String docNumber;
  final DateTime docDate;
  final DateTime? dueDate;
  final ValueChanged<List<QuotationLineItem>> onChanged;

  const BillingEditView({
    super.key,
    required this.lineItems,
    required this.vatPercentage,
    required this.docType,
    required this.docNumber,
    required this.docDate,
    required this.onChanged,
    this.dueDate,
  });

  @override
  State<BillingEditView> createState() => _BillingEditViewState();
}

class _BillingEditViewState extends State<BillingEditView> {
  late List<QuotationLineItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.lineItems);
  }

  @override
  void didUpdateWidget(BillingEditView old) {
    super.didUpdateWidget(old);
    // Only sync from outside if the identity of the list changed
    // (e.g. new document selected), not on every keystroke
    if (old.docNumber != widget.docNumber) {
      _items = List.from(widget.lineItems);
    }
  }

  void _updateItem(int index, QuotationLineItem updated) {
    setState(() => _items[index] = updated);
    widget.onChanged(List.from(_items));
  }

  void _addLine() {
    final nextId = (_items.length + 1).toString();
    setState(() {
      _items.add(
        QuotationLineItem(id: nextId, description: '', qty: 1, unitPrice: 0),
      );
    });
    widget.onChanged(List.from(_items));
  }

  void _removeLine(int index) {
    setState(() => _items.removeAt(index));
    widget.onChanged(List.from(_items));
  }

  double get _subTotal => _items.fold(0, (s, i) => s + i.amount);
  double get _total => _subTotal + (_subTotal * widget.vatPercentage / 100);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Header — identical to BillingDocumentView ─────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo zone (static — same as BillingDocumentView)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  child: Icon(
                    Icons.image,
                    size: 45,
                    color: Colors.grey.shade400,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      'Building No : 2872, Al Kharj Rd',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text('6858 Al Dilaa Dist', style: TextStyle(fontSize: 13)),
                    Text('Riyadh : 14315', style: TextStyle(fontSize: 13)),
                    Text(
                      'Riyadh, Kingdom of Saudi Arabia',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Document type divider ──────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                Divider(color: Colors.grey.shade200, thickness: 1.3),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.docType,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Edit mode indicator chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _T.blue50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _T.blue.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 10, color: _T.blue),
                            SizedBox(width: 4),
                            Text(
                              'Editing',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _T.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Client + doc info ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quote to', style: const TextStyle(fontSize: 11.5)),
                    const SizedBox(height: 6),
                    const Text(
                      'Scott, Melba R.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '2468 Blackwell Street\nFairbanks\n99701\nUAE',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${widget.docType == 'INVOICE' ? 'Invoice' : 'Quote'}#:',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        Text(
                          ' ${widget.docNumber}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Date: ${fmtDate(widget.docDate)}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    if (widget.dueDate != null)
                      Text(
                        'Due: ${fmtDate(widget.dueDate!)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _T.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Text(
                      'Terms: Due on Receipt',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Editable table ─────────────────────────────────────────
            _EditableTable(
              items: _items,
              onUpdate: _updateItem,
              onRemove: _removeLine,
              onAdd: _addLine,
            ),

            // ── Totals — live, matches BillingDocumentView layout ──────
            DefaultTextStyle(
              style: const TextStyle(fontSize: 10.8, color: Colors.black),
              child: Container(
                width: 250,
                decoration: BoxDecoration(color: const Color(0xFFf5f3f4)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('Sub Total'),
                          SizedBox(height: 13),
                          Text('Tax Rate'),
                          SizedBox(height: 13),
                          Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_subTotal.toStringAsFixed(2)),
                        const SizedBox(height: 13),
                        Text('${widget.vatPercentage.toStringAsFixed(2)}%'),
                        const SizedBox(height: 13),
                        Text(
                          'AED ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Balance due
            DefaultTextStyle(
              style: const TextStyle(fontSize: 10.8, color: Colors.black),
              child: Container(
                width: 250,
                decoration: BoxDecoration(color: const Color(0xFFe3f2eb)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 90,
                      alignment: Alignment.centerRight,
                      child: const Text(
                        'Balance Due',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'AED ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Terms
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Terms & Conditions',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Full payment is due upon receipt of the invoice.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDITABLE TABLE
//
// Replaces BillingDocumentView's TableHeader + LineItem rows with an
// editable version. The column layout is identical — same widths, same
// VertDivider separators — so the edit view is visually indistinguishable
// from the final document except for the tappable cells.
// ─────────────────────────────────────────────────────────────────────────────
class _EditableTable extends StatelessWidget {
  final List<QuotationLineItem> items;
  final void Function(int, QuotationLineItem) onUpdate;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  const _EditableTable({
    required this.items,
    required this.onUpdate,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Same TableHeader as BillingDocumentView
        const TableHeader(isEditMode: true),

        // Editable rows
        ...items.asMap().entries.map(
          (e) => _EditableLineItem(
            key: ValueKey(e.value.id),
            index: e.key,
            item: e.value,
            isLast: e.key == items.length - 1,
            onUpdate: (updated) => onUpdate(e.key, updated),
            onRemove: () => onRemove(e.key),
          ),
        ),

        // Add line row
        _AddLineRow(onTap: onAdd),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDITABLE LINE ITEM
//
// Matches the exact column layout of LineItem in BillingDocumentView:
//   VertDivider | # (35px) | VertDivider | Description (flex) |
//   VertDivider | Qty (70px) | VertDivider | Rate (70px) |
//   VertDivider | Amount (70px) | VertDivider
//
// Tappable cells get a subtle blue border on focus and a faint blue50 bg.
// The row also shows a × remove button on hover (right side, outside the
// last VertDivider) — ghost icon that turns red on its own hover.
//
// Amount is always computed (qty × rate) — never directly editable.
// ─────────────────────────────────────────────────────────────────────────────
class _EditableLineItem extends StatefulWidget {
  final int index;
  final QuotationLineItem item;
  final bool isLast;
  final ValueChanged<QuotationLineItem> onUpdate;
  final VoidCallback onRemove;

  const _EditableLineItem({
    super.key,
    required this.index,
    required this.item,
    required this.isLast,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_EditableLineItem> createState() => _EditableLineItemState();
}

class _EditableLineItemState extends State<_EditableLineItem> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _subTitleCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _rateCtrl;

  bool _rowHovered = false;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _descCtrl = TextEditingController(text: i.description);
    _subTitleCtrl = TextEditingController(text: i.subTitle ?? '');
    _qtyCtrl = TextEditingController(
      text:
          i.qty == i.qty.truncateToDouble()
              ? i.qty.toInt().toString()
              : i.qty.toStringAsFixed(2),
    );
    _rateCtrl = TextEditingController(
      text: i.unitPrice == 0 ? '' : i.unitPrice.toStringAsFixed(2),
    );

    for (final c in [_descCtrl, _subTitleCtrl, _qtyCtrl, _rateCtrl]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() {
    widget.onUpdate(
      QuotationLineItem(
        id: widget.item.id,
        taskId: widget.item.taskId,
        description: _descCtrl.text,
        subTitle: _subTitleCtrl.text.isEmpty ? null : _subTitleCtrl.text,
        qty: double.tryParse(_qtyCtrl.text) ?? widget.item.qty,
        unitPrice: double.tryParse(_rateCtrl.text) ?? 0,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _subTitleCtrl, _qtyCtrl, _rateCtrl]) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  double get _amount {
    final q = double.tryParse(_qtyCtrl.text) ?? widget.item.qty;
    final r = double.tryParse(_rateCtrl.text) ?? 0;
    return q * r;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _rowHovered = true),
      onExit: (_) => setState(() => _rowHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color:
            _rowHovered
                ? const Color(0xFFF0F7FF) // very faint blue tint on row hover
                : Colors.white,
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // # column
                VertDivider(height: _columnHeight),
                SizedBox(
                  width: 35,
                  height: _columnHeight,
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // Description column — editable
                VertDivider(height: _columnHeight),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      kLeftPaddingDescriptionColumn,
                      10,
                      15,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main description field
                        _EditCell(
                          controller: _descCtrl,
                          hint: 'Item description',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Sub-title field (smaller, grey)
                        _EditCell(
                          controller: _subTitleCtrl,
                          hint: 'Sub-title or notes (optional)',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Qty column — editable
                VertDivider(height: _columnHeight),
                SizedBox(
                  width: 70,
                  height: _columnHeight,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _EditCell(
                        controller: _qtyCtrl,
                        hint: '0',
                        numeric: true,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                // Rate column — editable
                VertDivider(height: _columnHeight),
                SizedBox(
                  width: 70,
                  height: _columnHeight,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _EditCell(
                        controller: _rateCtrl,
                        hint: '0.00',
                        numeric: true,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                // Amount column — computed, not editable
                VertDivider(height: _columnHeight),
                SizedBox(
                  width: 70,
                  height: _columnHeight,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      _amount.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 12.5,
                        color:
                            _amount > 0 ? Colors.black : Colors.grey.shade400,
                        fontWeight:
                            _amount > 0 ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                VertDivider(height: _columnHeight),

                // Remove button — appears on row hover
                AnimatedOpacity(
                  opacity: _rowHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 120),
                  child: _RemoveRowButton(onTap: widget.onRemove),
                ),
                VertDivider(height: _columnHeight),
              ],
            ),

            // Bottom border (unless last row — BillingDocumentView adds it
            // separately via the isLast flag in LineItem)
            if (!widget.isLast)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: 1, color: kTableDividerColor),
              ),
          ],
        ),
      ),
    );
  }

  // Height matches _kLineColumnVerticalDividerHeight from BillingDocumentView
  // (description + subtitle adds ~28px over the base 66px)
  double get _columnHeight => kLineColumnVerticalDividerHeight + 28;
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT CELL — inline text field styled to blend with document typography
//
// Unfocused: transparent background, no border — looks like plain text.
// Focused:   white bg, blue border (1.5px), slight elevation via shadow.
// This makes it feel like you're clicking on the document itself, not a form.
// ─────────────────────────────────────────────────────────────────────────────
class _EditCell extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextStyle style;
  final bool numeric;
  final TextAlign textAlign;

  const _EditCell({
    required this.controller,
    required this.hint,
    required this.style,
    this.numeric = false,
    this.textAlign = TextAlign.left,
  });

  @override
  State<_EditCell> createState() => _EditCellState();
}

class _EditCellState extends State<_EditCell> {
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
      duration: const Duration(milliseconds: 130),
      decoration: BoxDecoration(
        color: _focused ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _focused ? _T.blue : Colors.transparent,
          width: 1.5,
        ),
        boxShadow:
            _focused
                ? [
                  BoxShadow(
                    color: _T.blue.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
                : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        textAlign: widget.textAlign,
        keyboardType:
            widget.numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        inputFormatters:
            widget.numeric
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                : null,
        style: widget.style,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: widget.style.copyWith(color: Colors.grey.shade400),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD LINE ROW — matches the table's column divider structure
// ─────────────────────────────────────────────────────────────────────────────
class _AddLineRow extends StatefulWidget {
  final VoidCallback onTap;
  const _AddLineRow({required this.onTap});

  @override
  State<_AddLineRow> createState() => _AddLineRowState();
}

class _AddLineRowState extends State<_AddLineRow> {
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
          decoration: BoxDecoration(
            color: _hovered ? _T.blue50 : _T.slate50,
            border: Border(
              top: BorderSide(color: kTableDividerColor),
              bottom: BorderSide(color: kTableDividerColor),
            ),
          ),
          child: Row(
            children: [
              VertDivider(height: 36),
              const SizedBox(width: 35, height: 36),
              VertDivider(height: 36),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kLeftPaddingDescriptionColumn,
                    0,
                    0,
                    0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 13,
                        color: _hovered ? _T.blue : _T.slate400,
                      ),
                      const SizedBox(width: 5),
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
              VertDivider(height: 36),
              const SizedBox(width: 70, height: 36),
              VertDivider(height: 36),
              const SizedBox(width: 70, height: 36),
              VertDivider(height: 36),
              const SizedBox(width: 70, height: 36),
              VertDivider(height: 36),
              SizedBox(width: 29),
              VertDivider(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REMOVE ROW BUTTON — shown outside the table on row hover
// ─────────────────────────────────────────────────────────────────────────────
class _RemoveRowButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RemoveRowButton({required this.onTap});

  @override
  State<_RemoveRowButton> createState() => _RemoveRowButtonState();
}

class _RemoveRowButtonState extends State<_RemoveRowButton> {
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
          duration: const Duration(milliseconds: 100),
          width: 23,
          height: 23,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: _hovered ? _T.red50 : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 12,
            color: _hovered ? _T.red : _T.slate300,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOC TOPBAR — Edit/Preview toggle + status + close
// ─────────────────────────────────────────────────────────────────────────────
class _DocTopbar extends StatelessWidget {
  final String number;
  final String subtitle;
  final _DocMode mode;
  final ValueChanged<_DocMode> onModeChanged;
  final VoidCallback onClose;
  final Widget trailing;

  const _DocTopbar({
    required this.number,
    required this.subtitle,
    required this.mode,
    required this.onModeChanged,
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
          // Close
          CloseBtn(onTap: onClose),
          const SizedBox(width: 14),

          // Number + project
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

          const SizedBox(width: 16),

          // Edit / Preview toggle — pill style
          _ModeToggle(current: mode, onChange: onModeChanged),

          const Spacer(),

          trailing,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODE TOGGLE
// ─────────────────────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final _DocMode current;
  final ValueChanged<_DocMode> onChange;

  const _ModeToggle({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _T.slate100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeTab(
            icon: Icons.edit_outlined,
            label: 'Edit',
            active: current == _DocMode.edit,
            onTap: () => onChange(_DocMode.edit),
          ),
          const SizedBox(width: 2),
          _ModeTab(
            icon: Icons.visibility_outlined,
            label: 'Preview',
            active: current == _DocMode.preview,
            onTap: () => onChange(_DocMode.preview),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_ModeTab> createState() => _ModeTabState();
}

class _ModeTabState extends State<_ModeTab> {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:
                widget.active
                    ? _T.white
                    : (_hovered ? _T.slate50 : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            boxShadow:
                widget.active
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 12,
                color: widget.active ? _T.ink2 : _T.slate400,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
                  color: widget.active ? _T.ink2 : _T.slate400,
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
// REMAINING SHARED WIDGETS (trimmed — only what's still used)
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceCreatedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
  );
}

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

// ─────────────────────────────────────────────────────────────────────────────
// LIST PANEL + ROWS (unchanged from previous version, kept minimal)
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

  void _showPicker() {
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
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: _showPicker,
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
                  final cnt =
                      widget.tasks.where((t) => t.projectId == p.id).length;
                  return _ProjectPickerRow(
                    project: p,
                    taskCount: cnt,
                    selected: sel,
                    onTap: () => setState(() => _selected = p),
                  );
                },
              ),
            ),

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

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: GhostActionButton(
                      label: 'Cancel',
                      icon: Icons.cancel,
                      color: _T.slate500,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    // GhostBtn(
                    //   label: 'Cancel',
                    //   onTap: () => Navigator.of(context).pop(),
                    // ),
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
                              : () => onCreate(_selected!, _projectTasks),
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

  void onCreate(Project p, List<Task> tasks) => widget.onCreate(p, tasks);
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
  Widget build(BuildContext context) => MouseRegion(
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
              const Icon(Icons.check_circle_rounded, size: 14, color: _T.blue),
            ],
          ],
        ),
      ),
    ),
  );
}

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
    (p) => p?.id == id,
    orElse: () => null,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.slate50,
        border: Border(right: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        children: [
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
              dividerColor: Colors.grey.shade200,
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
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
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
                          fmtCurrency(q.total),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _T.ink3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          fmtDate(q.createdAt),
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
                          fmtCurrency(inv.total),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _T.ink3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          fmtDate(inv.createdAt),
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

class GhostBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const GhostBtn({required this.label, this.onTap});

  @override
  State<GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<GhostBtn> {
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
