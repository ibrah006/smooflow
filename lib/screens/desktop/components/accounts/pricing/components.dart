import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooflow/core/models/company.dart';
import 'package:smooflow/core/models/pricing.dart';
import 'package:smooflow/screens/desktop/components/action_buttons.dart';
import 'package:smooflow/screens/desktop/components/close_btn.dart';
import 'package:smooflow/screens/desktop/components/dialog_buttons.dart';
import 'package:smooflow/screens/desktop/components/field_label.dart';
import 'package:smooflow/screens/desktop/components/smoofield.dart';
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
  static const indigo = Color(0xFF6366F1);
  static const indigo50 = Color(0xFFEEF2FF);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate700 = Color(0xFF334155);
  static const slate900 = Color(0xFF0F172A);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class MainTabButton extends StatelessWidget {
  final String label;
  final int index;
  final TabController controller;

  const MainTabButton({
    required this.label,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.index == index;
    return GestureDetector(
      onTap: () => controller.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? _T.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? _T.ink2 : _T.slate500,
          ),
        ),
      ),
    );
  }
}

class NewPricingButton extends StatefulWidget {
  final VoidCallback onTap;
  const NewPricingButton({required this.onTap});

  @override
  State<NewPricingButton> createState() => _NewPricingButtonState();
}

class _NewPricingButtonState extends State<NewPricingButton> {
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
              'New Price List',
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

// ─────────────────────────────────────────────────────────────────────────────
// PRICING LIST PANEL
// ─────────────────────────────────────────────────────────────────────────────
class PricingListPanel extends StatelessWidget {
  final List<Pricing> pricingList;
  final String? selectedId;
  final ValueChanged<Pricing> onSelect;
  final VoidCallback onCreate;

  const PricingListPanel({
    required this.pricingList,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.slate50,
        border: Border(right: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate100)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.price_change_outlined,
                  size: 16,
                  color: _T.indigo,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Price Lists',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.ink2,
                  ),
                ),
                const Spacer(),
                if (pricingList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _T.slate200,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${pricingList.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _T.slate500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // List
          Expanded(
            child:
                pricingList.isEmpty
                    ? _EmptyPricingList(onCreate: onCreate)
                    : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: pricingList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final p = pricingList[i];
                        return _PricingListRow(
                          pricing: p,
                          selected: selectedId == p.id,
                          onTap: () => onSelect(p),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _PricingListRow extends StatefulWidget {
  final Pricing pricing;
  final bool selected;
  final VoidCallback onTap;

  const _PricingListRow({
    required this.pricing,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PricingListRow> createState() => _PricingListRowState();
}

class _PricingListRowState extends State<_PricingListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pricing;
    final sel = widget.selected;
    final defaultCosts = p.getPricingForClient('default');
    final customClientCount = p.clientsWithCustomPricing.length;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                sel
                    ? _T.blue50
                    : _hovered
                    ? _T.slate50
                    : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: sel ? _T.blue.withOpacity(0.3) : _T.slate200,
              width: 1,
            ),
            boxShadow:
                sel
                    ? [
                      BoxShadow(
                        color: _T.blue.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : _hovered
                    ? [
                      BoxShadow(
                        color: _T.slate900.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            children: [
              // Icon badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      sel
                          ? _T.blue.withOpacity(0.12)
                          : (_hovered ? _T.slate200 : _T.slate100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.price_change_outlined,
                  size: 14,
                  color: sel ? _T.blue : _T.slate400,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.description,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? _T.blue : _T.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _CostChip(
                          label: fmtCurrency(defaultCosts.printCost),
                          suffix: 'print',
                          selected: sel,
                        ),
                        _CostChip(
                          label: fmtCurrency(defaultCosts.applicationCost),
                          suffix: 'install',
                          selected: sel,
                        ),
                      ],
                    ),
                    if (customClientCount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _T.indigo,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$customClientCount client${customClientCount == 1 ? '' : 's'} with custom pricing',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _T.indigo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: sel || _hovered ? 1.0 : 0.0,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: sel ? _T.blue : _T.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small inline cost pill used in the pricing row.
class _CostChip extends StatelessWidget {
  final String label;
  final String suffix;
  final bool selected;

  const _CostChip({
    required this.label,
    required this.suffix,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: selected ? _T.blue.withOpacity(0.08) : _T.slate100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: selected ? _T.blue : _T.slate700,
              ),
            ),
            TextSpan(
              text: ' $suffix',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: selected ? _T.blue.withOpacity(0.7) : _T.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPricingList extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyPricingList({required this.onCreate});

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
          child: const Icon(
            Icons.price_change_outlined,
            size: 20,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'No price lists yet',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Click "New Price List" to create one',
          style: TextStyle(fontSize: 11.5, color: _T.slate300),
        ),
        const SizedBox(height: 16),
        GhostActionButton(
          label: 'Create Price List',
          icon: Icons.cancel,
          color: _T.slate500,
          onTap: onCreate,
        ),
      ],
    ),
  );
}

class PricingIdlePane extends StatelessWidget {
  final VoidCallback onCreate;

  const PricingIdlePane({required this.onCreate});

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
              Icons.price_change_outlined,
              size: 24,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Select a price list',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'or click "New Price List" to create one',
            style: TextStyle(fontSize: 12, color: _T.slate300),
          ),
          const SizedBox(height: 16),
          GhostActionButton(
            label: 'Create Price List',
            icon: Icons.cancel,
            color: _T.slate500,
            onTap: onCreate,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PRICING DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────
class PricingDetailPanel extends StatefulWidget {
  final Pricing pricing;
  final List<Company> companies;
  final ValueChanged<Pricing> onUpdate;
  final VoidCallback onClose;

  const PricingDetailPanel({
    super.key,
    required this.pricing,
    required this.companies,
    required this.onUpdate,
    required this.onClose,
  });

  @override
  State<PricingDetailPanel> createState() => _PricingDetailPanelState();
}

class _PricingDetailPanelState extends State<PricingDetailPanel> {
  late Pricing _pricing;
  late TextEditingController _descCtrl;
  String? _selectedClientId;
  PricingCosts? _editingClientCosts;

  @override
  void initState() {
    super.initState();
    _pricing = widget.pricing;
    _descCtrl = TextEditingController(text: _pricing.description);
    _descCtrl.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _descCtrl.removeListener(_onDescriptionChanged);
    _descCtrl.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    if (_descCtrl.text != _pricing.description) {
      final updated = Pricing(
        id: _pricing.id,
        description: _descCtrl.text,
        organizationId: _pricing.organizationId,
        organization: _pricing.organization,
        clientPrices: _pricing.clientPrices,
        createdAt: _pricing.createdAt,
        updatedAt: DateTime.now(),
      );
      _pricing = updated;
      widget.onUpdate(updated);
    }
  }

  void _updateDefaultPricing(PricingCosts costs) {
    final updated = _pricing.copyWithDefaultPricing(costs);
    _pricing = updated;
    widget.onUpdate(updated);
  }

  void _setClientPricing(String clientId, PricingCosts costs) {
    final updated = _pricing.copyWithClientPricing(clientId, costs);
    _pricing = updated;
    widget.onUpdate(updated);
    setState(() {
      _selectedClientId = null;
      _editingClientCosts = null;
    });
  }

  void _removeClientPricing(String clientId) {
    final updated = _pricing.removeClientPricing(clientId);
    _pricing = updated;
    widget.onUpdate(updated);
  }

  void _editClientPricing(String clientId) {
    final costs = _pricing.getPricingForClient(clientId);
    setState(() {
      _selectedClientId = clientId;
      _editingClientCosts = costs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultCosts = _pricing.getPricingForClient('default');
    final customClients = _pricing.clientsWithCustomPricing;
    final availableClients =
        widget.companies.where((c) => !customClients.contains(c.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Topbar — matches create task screen
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: _T.white,
            border: Border(bottom: BorderSide(color: _T.slate100)),
          ),
          child: Row(
            children: [
              CloseBtn(onTap: widget.onClose),
              const SizedBox(width: 14),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _T.indigo50,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.price_change_outlined,
                  size: 14,
                  color: _T.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _descCtrl,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.ink2,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Price list name',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 20, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price List Configuration',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _T.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Set default pricing and client-specific rates.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _T.slate400,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section 1: Default Pricing ───────────────────────
                  _SectionCard(
                    icon: Icons.currency_franc_rounded,
                    iconColor: _T.green,
                    iconBg: _T.green50,
                    title: 'Default Pricing',
                    subtitle: 'Applied when no client-specific pricing is set',
                    child: _PricingEditCard(
                      costs: defaultCosts,
                      onSave: _updateDefaultPricing,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 2: Client-Specific Pricing ───────────────
                  _SectionCard(
                    icon: Icons.business_center_rounded,
                    iconColor: _T.indigo,
                    iconBg: _T.indigo50,
                    title: 'Client-Specific Pricing',
                    subtitle: 'Override default rates for specific clients',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customClients.isEmpty)
                          _EmptyClientPricing(
                            onAdd: () => _showClientPicker(availableClients),
                          )
                        else
                          ...customClients.map((clientId) {
                            final client = widget.companies.firstWhere(
                              (c) => c.id == clientId,
                              orElse: () => Company.sample(),
                            );
                            final costs = _pricing.getPricingForClient(
                              clientId,
                            );
                            return _ClientPricingRow(
                              client: client,
                              costs: costs,
                              onRemove: () => _removeClientPricing(clientId),
                              onSave: _setClientPricing,
                            );
                          }),
                        if (availableClients.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _AddClientButton(
                              onTap: () => _showClientPicker(availableClients),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showClientPicker(List<Company> clients) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder:
          (_) => _ClientPickerDialog(
            clients: clients,
            onSelect: (clientId) {
              _editClientPricing(clientId);
            },
          ),
    );
  }
}

class PricingCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final PricingCosts costs;
  final ValueChanged<PricingCosts> onSave;

  const PricingCard({
    required this.title,
    required this.subtitle,
    required this.costs,
    required this.onSave,
  });

  @override
  State<PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<PricingCard> {
  late TextEditingController _printCtrl;
  late TextEditingController _appCtrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _printCtrl = TextEditingController(
      text:
          widget.costs.printCost == 0
              ? ''
              : widget.costs.printCost.toStringAsFixed(2),
    );
    _appCtrl = TextEditingController(
      text:
          widget.costs.applicationCost == 0
              ? ''
              : widget.costs.applicationCost.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _printCtrl.dispose();
    _appCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final printCost = double.tryParse(_printCtrl.text.trim()) ?? 0;
    final appCost = double.tryParse(_appCtrl.text.trim()) ?? 0;
    widget.onSave(PricingCosts(printCost: printCost, applicationCost: appCost));
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.currency_franc_rounded,
                  size: 16,
                  color: _T.indigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _T.ink2,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _T.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isEditing)
                  _GhostIconButton(
                    icon: Icons.edit_outlined,
                    onTap: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _T.slate100),
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                _isEditing
                    ? Column(
                      children: [
                        _CostInputField(
                          label: 'Print Cost (per sqm)',
                          controller: _printCtrl,
                          hint: '0.00',
                        ),
                        const SizedBox(height: 12),
                        _CostInputField(
                          label: 'Installation Cost (per sqm)',
                          controller: _appCtrl,
                          hint: '0.00',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GhostActionButton(
                                label: 'Cancel',
                                icon: Icons.cancel,
                                color: _T.slate500,
                                onTap: () {
                                  setState(() => _isEditing = false);
                                  _printCtrl.text =
                                      widget.costs.printCost == 0
                                          ? ''
                                          : widget.costs.printCost
                                              .toStringAsFixed(2);
                                  _appCtrl.text =
                                      widget.costs.applicationCost == 0
                                          ? ''
                                          : widget.costs.applicationCost
                                              .toStringAsFixed(2);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: GreenActionButton(
                                label: 'Save',
                                icon: Icons.save_rounded,
                                // enabled: true,
                                onTap: _save,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        _CostDisplay(
                          label: 'Print',
                          value: widget.costs.printCost,
                          unit: '/sqm',
                        ),
                        const SizedBox(width: 16),
                        _CostDisplay(
                          label: 'Installation',
                          value: widget.costs.applicationCost,
                          unit: '/sqm',
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

class _ClientPricingRow extends StatefulWidget {
  final Company client;
  final PricingCosts costs;
  final VoidCallback onRemove;
  final Function(String clientId, PricingCosts) onSave;

  const _ClientPricingRow({
    required this.client,
    required this.costs,
    required this.onRemove,
    required this.onSave,
  });

  @override
  State<_ClientPricingRow> createState() => _ClientPricingRowState();
}

class _ClientPricingRowState extends State<_ClientPricingRow> {
  late TextEditingController _printCtrl;

  late TextEditingController _appCtrl;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _printCtrl = TextEditingController(
      text:
          widget.costs.printCost == 0
              ? ''
              : widget.costs.printCost.toStringAsFixed(2),
    );
    _appCtrl = TextEditingController(
      text:
          widget.costs.applicationCost == 0
              ? ''
              : widget.costs.applicationCost.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _printCtrl.dispose();
    _appCtrl.dispose();
    super.dispose();
  }

  void _onCancel() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.client.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    widget.client.initials,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.client.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.client.name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _T.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      children: [
                        Text(
                          'Print: ${fmtCurrency(widget.costs.printCost)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Install: ${fmtCurrency(widget.costs.applicationCost)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isEditing) ...[
                _GhostIconButton(
                  icon: Icons.edit_outlined,
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
                const SizedBox(width: 4),
                _GhostIconButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: widget.onRemove,
                  color: _T.red,
                ),
              ],
            ],
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _CostInputField(
                    label: 'Print Cost (per sqm)',
                    controller: _printCtrl,
                    hint: '0.00',
                  ),
                  const SizedBox(height: 16),
                  _CostInputField(
                    label: 'Installation Cost (per sqm)',
                    controller: _appCtrl,
                    hint: '0.00',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GhostActionButton(
                          label: 'Cancel',
                          icon: Icons.cancel,
                          color: _T.slate500,
                          onTap: _onCancel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GreenActionButton(
                          label: 'Save Pricing',
                          icon: Icons.save_rounded,
                          onTap: () {
                            _isEditing = false;
                            final printCost =
                                double.tryParse(_printCtrl.text.trim()) ?? 0;
                            final appCost =
                                double.tryParse(_appCtrl.text.trim()) ?? 0;
                            widget.onSave(
                              widget.client.id,
                              PricingCosts(
                                printCost: printCost,
                                applicationCost: appCost,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AddClientPricingButton extends StatefulWidget {
  final List<Company> clients;
  final ValueChanged<String> onSelect;

  const _AddClientPricingButton({
    required this.clients,
    required this.onSelect,
  });

  @override
  State<_AddClientPricingButton> createState() =>
      _AddClientPricingButtonState();
}

class _AddClientPricingButtonState extends State<_AddClientPricingButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _showClientPicker(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered ? _T.blue50 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered ? _T.blue.withOpacity(0.4) : _T.slate200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 12,
                color: _hovered ? _T.blue : _T.slate500,
              ),
              const SizedBox(width: 4),
              Text(
                'Add Client',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? _T.blue : _T.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientPicker() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder:
          (_) => _ClientPickerDialog(
            clients: widget.clients,
            onSelect: widget.onSelect,
          ),
    );
  }
}

class _ClientPickerDialog extends StatelessWidget {
  final List<Company> clients;
  final ValueChanged<String> onSelect;

  const _ClientPickerDialog({required this.clients, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl),
          border: Border.all(color: _T.slate200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    ),
                    child: const Icon(
                      Icons.business_center_rounded,
                      size: 15,
                      color: _T.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Client',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _T.ink,
                      ),
                    ),
                  ),
                  DialogCloseButton(onTap: () => Navigator.of(context).pop()),
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
                itemCount: clients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final c = clients[i];
                  return _ClientPickerRow(
                    client: c,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(c.id);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ClientPickerRow extends StatefulWidget {
  final Company client;
  final VoidCallback onTap;

  const _ClientPickerRow({required this.client, required this.onTap});

  @override
  State<_ClientPickerRow> createState() => _ClientPickerRowState();
}

class _ClientPickerRowState extends State<_ClientPickerRow> {
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
          color: _hovered ? _T.slate50 : _T.white,
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(color: _T.slate200),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.client.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.client.name,
                style: const TextStyle(fontSize: 13, color: _T.ink3),
              ),
            ),
            if (_hovered)
              const Icon(Icons.chevron_right_rounded, size: 14, color: _T.blue),
          ],
        ),
      ),
    ),
  );
}

class _CostInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _CostInputField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _T.ink3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: 'AED ',
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
              borderSide: const BorderSide(color: _T.blue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _GhostIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _GhostIconButton({required this.icon, required this.onTap, this.color});

  @override
  State<_GhostIconButton> createState() => _GhostIconButtonState();
}

class _GhostIconButtonState extends State<_GhostIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _T.slate500;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: _hovered ? color : _T.slate400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE PRICING PANEL
// ─────────────────────────────────────────────────────────────────────────────
class CreatePricingPanel extends StatefulWidget {
  final List<Company> companies;
  final ValueChanged<Pricing> onCreate;
  final VoidCallback onCancel;

  const CreatePricingPanel({
    required this.companies,
    required this.onCreate,
    required this.onCancel,
  });

  @override
  State<CreatePricingPanel> createState() => _CreatePricingPanelState();
}

class _CreatePricingPanelState extends State<CreatePricingPanel> {
  final _descCtrl = TextEditingController();
  final _printCtrl = TextEditingController();
  final _appCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _descTouched = false;

  bool get _isValid => _descCtrl.text.trim().isNotEmpty;

  Future<void> _create() async {
    if (!_isValid) {
      setState(() => _descTouched = true);
      return;
    }

    setState(() => _isSubmitting = true);

    final printCost = double.tryParse(_printCtrl.text.trim()) ?? 0;
    final appCost = double.tryParse(_appCtrl.text.trim()) ?? 0;

    final pricing = Pricing.create(
      description: _descCtrl.text.trim(),
      organizationId: '', // Will be set by provider
      clientPrices: {
        'default': PricingCosts(printCost: printCost, applicationCost: appCost),
      },
    );

    widget.onCreate(pricing);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _printCtrl.dispose();
    _appCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Topbar
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: _T.white,
            border: Border(bottom: BorderSide(color: _T.slate100)),
          ),
          child: Row(
            children: [
              CloseBtn(onTap: widget.onCancel),
              const SizedBox(width: 14),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _T.indigo50,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.price_change_outlined,
                  size: 14,
                  color: _T.indigo,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'New Price List',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _T.ink2,
                ),
              ),
              const Spacer(),
              GreenActionButton(
                label: _isSubmitting ? 'Creating...' : 'Create',
                icon: Icons.add_rounded,
                loading: _isSubmitting,
                enabled: !_isSubmitting && _isValid,
                onTap: _create,
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 20, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Price List',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _T.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create a new price list for your products and services.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _T.slate400,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section 1: Basic Info ────────────────────────────
                  _SectionCard(
                    icon: Icons.title_outlined,
                    iconColor: _T.blue,
                    iconBg: _T.blue50,
                    title: 'Basic Information',
                    subtitle: 'Name and identification',
                    child: SmooField(
                      controller: _descCtrl,
                      label: 'Price List Name',
                      hint: 'e.g., Standard Vinyl Pricing',
                      icon: Icons.title_outlined,
                      required: true,
                      error:
                          _descTouched && !_isValid ? 'Name is required' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 2: Default Pricing ───────────────────────
                  _SectionCard(
                    icon: Icons.currency_franc_rounded,
                    iconColor: _T.green,
                    iconBg: _T.green50,
                    title: 'Default Pricing',
                    subtitle: 'Base rates for all clients',
                    child: Column(
                      children: [
                        _PricingInputField(
                          controller: _printCtrl,
                          label: 'Print Cost',
                          hint: '0.00',
                          unit: '/sqm',
                        ),
                        const SizedBox(height: 16),
                        _PricingInputField(
                          controller: _appCtrl,
                          label: 'Installation Cost',
                          hint: '0.00',
                          unit: '/sqm',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _T.slate50,
                            borderRadius: BorderRadius.circular(_T.r),
                            border: Border.all(color: _T.slate200),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.tips_and_updates_outlined,
                                size: 12,
                                color: _T.slate500,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You can add client-specific pricing after creating the price list.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _T.slate500,
                                    fontWeight: FontWeight.w400,
                                  ),
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
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRICING EDIT CARD — inline editing with save/cancel
// ─────────────────────────────────────────────────────────────────────────────
class _PricingEditCard extends StatefulWidget {
  final PricingCosts costs;
  final ValueChanged<PricingCosts> onSave;

  const _PricingEditCard({required this.costs, required this.onSave});

  @override
  State<_PricingEditCard> createState() => _PricingEditCardState();
}

class _PricingEditCardState extends State<_PricingEditCard> {
  late TextEditingController _printCtrl;
  late TextEditingController _appCtrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _printCtrl = TextEditingController(
      text:
          widget.costs.printCost == 0
              ? ''
              : widget.costs.printCost.toStringAsFixed(2),
    );
    _appCtrl = TextEditingController(
      text:
          widget.costs.applicationCost == 0
              ? ''
              : widget.costs.applicationCost.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _printCtrl.dispose();
    _appCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final printCost = double.tryParse(_printCtrl.text.trim()) ?? 0;
    final appCost = double.tryParse(_appCtrl.text.trim()) ?? 0;
    widget.onSave(PricingCosts(printCost: printCost, applicationCost: appCost));
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Column(
        children: [
          _PricingInputField(
            controller: _printCtrl,
            label: 'Print Cost',
            hint: '0.00',
            unit: '/sqm',
          ),
          const SizedBox(height: 16),
          _PricingInputField(
            controller: _appCtrl,
            label: 'Installation Cost',
            hint: '0.00',
            unit: '/sqm',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GhostActionButton(
                  label: 'Cancel',
                  icon: Icons.cancel,
                  color: _T.slate500,
                  onTap: () {
                    setState(() => _isEditing = false);
                    _printCtrl.text =
                        widget.costs.printCost == 0
                            ? ''
                            : widget.costs.printCost.toStringAsFixed(2);
                    _appCtrl.text =
                        widget.costs.applicationCost == 0
                            ? ''
                            : widget.costs.applicationCost.toStringAsFixed(2);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GreenActionButton(
                  label: 'Save',
                  icon: Icons.save_rounded,
                  loading: false,
                  enabled: true,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _CostDisplay(
          label: 'Print',
          value: widget.costs.printCost,
          unit: '/sqm',
        ),
        const SizedBox(width: 16),
        _CostDisplay(
          label: 'Installation',
          value: widget.costs.applicationCost,
          unit: '/sqm',
        ),
        const Spacer(),
        _GhostIconButton(
          icon: Icons.edit_outlined,
          onTap: () => setState(() => _isEditing = true),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRICING INPUT FIELD — matches _SmooField style
// ─────────────────────────────────────────────────────────────────────────────
class _PricingInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;

  const _PricingInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, optional: true),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _T.slate200),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  'AED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _T.slate500,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(
                    fontSize: 13,
                    color: _T.ink,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: _T.slate300,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _T.slate500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COST DISPLAY — pill-style chip
// ─────────────────────────────────────────────────────────────────────────────
class _CostDisplay extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const _CostDisplay({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _T.slate500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value == 0 ? 'Not offered' : fmtCurrency(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: value > 0 ? _T.ink3 : _T.slate400,
            ),
          ),
          if (value > 0)
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                color: _T.slate400,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD CLIENT BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _AddClientButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddClientButton({required this.onTap});

  @override
  State<_AddClientButton> createState() => _AddClientButtonState();
}

class _AddClientButtonState extends State<_AddClientButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? _T.blue50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: _hovered ? _T.blue.withOpacity(0.4) : _T.slate200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 14,
                color: _hovered ? _T.blue : _T.slate500,
              ),
              const SizedBox(width: 6),
              Text(
                'Add Client',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD
//
// Shadow removed — flat border only, matching board lane cards.
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.child,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: iconColor.withOpacity(0.2)),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _T.ink,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _T.slate400,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Divider(height: 1, color: _T.slate100),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY CLIENT PRICING STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyClientPricing extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyClientPricing({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        children: [
          const Icon(Icons.business_outlined, size: 32, color: _T.slate300),
          const SizedBox(height: 12),
          const Text(
            'No client-specific pricing',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add custom rates for specific clients',
            style: TextStyle(
              fontSize: 11.5,
              color: _T.slate400,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          GhostActionButton(
            label: 'Add Client',
            color: _T.slate500,
            icon: Icons.cancel,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}
