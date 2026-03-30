// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS PAGE
//
// Structured into four categories rendered as a two-column layout:
//   Left  — sticky nav rail listing each section
//   Right — scrollable content area, one section at a time
//
// Sections:
//   1. Profile          — personal info
//   2. Organization     — org name, role, private domain badge
//   3. Notifications    — per-topic toggles
//   4. Quotations & Invoices — company branding for templates
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooflow/core/models/organization.dart';
import 'package:smooflow/core/models/user.dart';

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
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

enum _Section { profile, organization, notifications, quotations }

class SettingsPage extends StatefulWidget {
  final Organization currentOrg;
  final User currentUser;
  final bool isAdmin;

  const SettingsPage({
    super.key,
    required this.currentOrg,
    required this.currentUser,
    required this.isAdmin,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _Section _active = _Section.profile;

  // ── Profile controllers ───────────────────────────────────────────────────
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  // ── Notification toggles ──────────────────────────────────────────────────
  bool _notifTaskUpdates = true;
  bool _notifBilling = true;
  bool _notifClients = false;
  bool _notifTeam = false;
  bool _notifPricingAdd = true;
  bool _notifPricingUpdate = true;

  // ── Quotations / Invoice branding ─────────────────────────────────────────
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _companyAddressCtrl;
  Uint8List? _logoBytes;
  String? _logoFileName;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.currentUser.name);
    final nameSplit = widget.currentUser.name.split(' ');
    if (nameSplit.length > 1) {
      nameSplit.removeAt(0);
      _lastNameCtrl = TextEditingController(text: nameSplit.join(' '));
    }
    _emailCtrl = TextEditingController(text: widget.currentUser.email);
    _phoneCtrl = TextEditingController(
      text: '${widget.currentUser.phone ?? 'N/a'}',
    );
    _companyNameCtrl = TextEditingController(text: widget.currentOrg.name);
    _companyAddressCtrl = TextEditingController(
      // Sample company address for now
      text:
          "2345 Sample Dist\nCity: 12345\nState, Country", //widget.currentOrg.companyAddress,
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _logoBytes = result.files.first.bytes;
      _logoFileName = result.files.first.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left nav rail ────────────────────────────────────────────
          _SettingsNav(
            active: _active,
            onSelect: (s) => setState(() => _active = s),
          ),

          // ── Vertical divider ─────────────────────────────────────────
          VerticalDivider(width: 1, thickness: 1, color: _T.slate200),

          // ── Content area ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder:
                      (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                  child: KeyedSubtree(
                    key: ValueKey(_active),
                    child: _buildSection(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_active) {
      case _Section.profile:
        return _ProfileSection(
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          emailCtrl: _emailCtrl,
          phoneCtrl: _phoneCtrl,
          user: widget.currentUser,
        );
      case _Section.organization:
        return _OrganizationSection(
          org: widget.currentOrg,
          isAdmin: widget.isAdmin,
          userRole: widget.currentUser.role,
        );
      case _Section.notifications:
        return _NotificationsSection(
          taskUpdates: _notifTaskUpdates,
          billing: _notifBilling,
          clients: _notifClients,
          team: _notifTeam,
          pricingAdd: _notifPricingAdd,
          pricingUpdate: _notifPricingUpdate,
          onChanged:
              (field, val) => setState(() {
                switch (field) {
                  case 'task':
                    _notifTaskUpdates = val;
                    break;
                  case 'billing':
                    _notifBilling = val;
                    break;
                  case 'clients':
                    _notifClients = val;
                    break;
                  case 'team':
                    _notifTeam = val;
                    break;
                  case 'pAdd':
                    _notifPricingAdd = val;
                    break;
                  case 'pUpdate':
                    _notifPricingUpdate = val;
                    break;
                }
              }),
        );
      case _Section.quotations:
        return _QuotationsSection(
          companyNameCtrl: _companyNameCtrl,
          companyAddressCtrl: _companyAddressCtrl,
          logoBytes: _logoBytes,
          logoFileName: _logoFileName,
          onPickLogo: _pickLogo,
          onRemoveLogo:
              () => setState(() {
                _logoBytes = null;
                _logoFileName = null;
              }),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT NAV RAIL
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsNav extends StatelessWidget {
  final _Section active;
  final ValueChanged<_Section> onSelect;

  const _SettingsNav({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _T.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Manage your preferences',
                  style: TextStyle(fontSize: 11, color: _T.slate400),
                ),
              ],
            ),
          ),

          // Nav groups
          _NavGroup(
            label: 'Account',
            children: [
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                section: _Section.profile,
                active: active,
                onTap: onSelect,
              ),
              _NavItem(
                icon: Icons.business_outlined,
                label: 'Organization',
                section: _Section.organization,
                active: active,
                onTap: onSelect,
              ),
            ],
          ),
          _NavGroup(
            label: 'Preferences',
            children: [
              _NavItem(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                section: _Section.notifications,
                active: active,
                onTap: onSelect,
              ),
            ],
          ),
          _NavGroup(
            label: 'Documents',
            children: [
              _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Quotations & Invoices',
                section: _Section.quotations,
                active: active,
                onTap: onSelect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _NavGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: _T.slate400,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final _Section section;
  final _Section active;
  final ValueChanged<_Section> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.section,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.section == widget.active;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.section),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color:
                sel
                    ? _T.blue.withOpacity(0.08)
                    : _hovered
                    ? _T.slate50
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: sel ? _T.blue : _T.slate500),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? _T.blue : _T.slate700,
                ),
              ),
              if (sel) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _T.blue,
                    shape: BoxShape.circle,
                  ),
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
// SECTION SCAFFOLD — consistent page header + content wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final Widget? action;

  const _SectionScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _T.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: _T.slate600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _T.slate400),
                  ),
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: 28),
        Divider(color: _T.slate100, thickness: 1),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS GROUP — labelled card group
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final String label;
  final String? description;
  final List<Widget> children;

  const _SettingsGroup({
    required this.label,
    required this.children,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _T.ink,
            letterSpacing: -0.1,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description!,
            style: const TextStyle(fontSize: 11, color: _T.slate400),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _T.slate200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS ROW — label + value or input inside a group
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;
  final bool divider;

  const _SettingsRow({
    required this.label,
    required this.child,
    this.hint,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label column
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _T.ink,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _T.slate400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Input / value
              Expanded(child: child),
            ],
          ),
        ),
        if (divider) Divider(height: 1, thickness: 1, color: _T.slate100),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE TEXT FIELD — used inside _SettingsRow
// ─────────────────────────────────────────────────────────────────────────────
class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  final TextInputType keyboardType;

  const _InlineField({
    required this.controller,
    this.placeholder = '',
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 12, color: _T.ink),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(fontSize: 12, color: _T.slate300),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: _T.slate50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _T.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _T.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _T.blue.withOpacity(0.5), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW — notification toggle row
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;
  final Widget? badge;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.divider = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _T.ink,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 7),
                          badge!,
                        ],
                      ],
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _T.slate400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _CompactSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        if (divider) Divider(height: 1, thickness: 1, color: _T.slate100),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT SWITCH — cleaner than CupertinoSwitch in this aesthetic
// ─────────────────────────────────────────────────────────────────────────────
class _CompactSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          color: value ? _T.blue : _T.slate200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2.5),
            width: 15,
            height: 15,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _T.ink,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Text(
          'Save changes',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 1 — PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileSection extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final User user;

  const _ProfileSection({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: 'Profile',
      subtitle: 'Your personal information and contact details.',
      icon: Icons.person_outline_rounded,
      action: _SaveButton(onTap: () {}),
      children: [
        // Avatar row
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _T.slate100,
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child:
                  user.avatarUrl == null
                      ? Text(
                        '${firstNameCtrl.text[0]}${lastNameCtrl.text.length > 0 ? lastNameCtrl.text[0] : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _T.slate500,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${firstNameCtrl.text}${lastNameCtrl.text.isNotEmpty ? ' ${lastNameCtrl.text}' : ''}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _T.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 11.5, color: _T.slate400),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        _SettingsGroup(
          label: 'Personal Information',
          children: [
            _SettingsRow(
              label: 'First name',
              child: _InlineField(controller: firstNameCtrl),
            ),
            _SettingsRow(
              label: 'Last name',
              child: _InlineField(controller: lastNameCtrl),
            ),
            _SettingsRow(
              label: 'Email address',
              hint: 'Used for login and notifications',
              child: _InlineField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            _SettingsRow(
              label: 'Phone number',
              divider: false,
              child: _InlineField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                placeholder: '+1 000 000 0000',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 2 — ORGANIZATION
// ─────────────────────────────────────────────────────────────────────────────
class _OrganizationSection extends StatelessWidget {
  final Organization org;
  final bool isAdmin;
  final String userRole;

  const _OrganizationSection({
    required this.org,
    required this.isAdmin,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: 'Organization',
      subtitle: 'Your workspace and role within the team.',
      icon: Icons.business_outlined,
      children: [
        _SettingsGroup(
          label: 'Workspace',
          children: [
            _SettingsRow(
              label: 'Organization name',
              divider: org.privateDomain != null && isAdmin,
              child: Text(
                org.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _T.ink,
                ),
              ),
            ),
            _SettingsRow(
              label: 'Your role',
              divider: isAdmin && org.privateDomain != null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor(userRole).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  userRole,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _roleColor(userRole),
                  ),
                ),
              ),
            ),
            if (isAdmin && org.privateDomain != null)
              _SettingsRow(
                label: 'Private domain',
                hint: 'Enforced login domain for your org',
                divider: false,
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _T.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      org.privateDomain!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _T.ink,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _T.blue;
      case 'manager':
        return _T.indigo;
      default:
        return _T.slate500;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 3 — NOTIFICATIONS
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationsSection extends StatelessWidget {
  final bool taskUpdates;
  final bool billing;
  final bool clients;
  final bool team;
  final bool pricingAdd;
  final bool pricingUpdate;
  final void Function(String field, bool val) onChanged;

  const _NotificationsSection({
    required this.taskUpdates,
    required this.billing,
    required this.clients,
    required this.team,
    required this.pricingAdd,
    required this.pricingUpdate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: 'Notifications',
      subtitle: 'Choose which in-app alerts you receive.',
      icon: Icons.notifications_none_rounded,
      children: [
        _SettingsGroup(
          label: 'Tasks',
          children: [
            _ToggleRow(
              label: 'Task updates',
              description:
                  'Alerts when tasks are assigned, updated or completed.',
              value: taskUpdates,
              divider: false,
              onChanged: (v) => onChanged('task', v),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _SettingsGroup(
          label: 'Billing',
          description: 'Quotation and invoice activity.',
          children: [
            _ToggleRow(
              label: 'Billing activity',
              description: 'New quotations, invoice additions and updates.',
              value: billing,
              divider: false,
              onChanged: (v) => onChanged('billing', v),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _SettingsGroup(
          label: 'People & Team',
          children: [
            _ToggleRow(
              label: 'Client updates',
              description: 'New clients added or client details changed.',
              value: clients,
              badge: _DefaultOffBadge(),
              onChanged: (v) => onChanged('clients', v),
            ),
            _ToggleRow(
              label: 'Team updates',
              description: 'Team member joins, role changes and removals.',
              value: team,
              badge: _DefaultOffBadge(),
              divider: false,
              onChanged: (v) => onChanged('team', v),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _SettingsGroup(
          label: 'Pricing Lists',
          children: [
            _ToggleRow(
              label: 'New pricing list added',
              value: pricingAdd,
              onChanged: (v) => onChanged('pAdd', v),
            ),
            _ToggleRow(
              label: 'Pricing list updated',
              value: pricingUpdate,
              divider: false,
              onChanged: (v) => onChanged('pUpdate', v),
            ),
          ],
        ),
      ],
    );
  }
}

class _DefaultOffBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: _T.slate100,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'off by default',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: _T.slate400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 4 — QUOTATIONS & INVOICES
// ─────────────────────────────────────────────────────────────────────────────
class _QuotationsSection extends StatelessWidget {
  final TextEditingController companyNameCtrl;
  final TextEditingController companyAddressCtrl;
  final Uint8List? logoBytes;
  final String? logoFileName;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;

  const _QuotationsSection({
    required this.companyNameCtrl,
    required this.companyAddressCtrl,
    required this.onPickLogo,
    required this.onRemoveLogo,
    this.logoBytes,
    this.logoFileName,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: 'Quotations & Invoices',
      subtitle: 'Company details printed on every document you issue.',
      icon: Icons.receipt_long_outlined,
      action: _SaveButton(onTap: () {}),
      children: [
        _SettingsGroup(
          label: 'Company Branding',
          description: 'Shown in the header of all generated documents.',
          children: [
            // Logo upload row — full-width treatment
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Company logo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _T.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Used in quotation and invoice templates. PNG or JPG, max 2 MB.',
                    style: TextStyle(fontSize: 10.5, color: _T.slate400),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Preview box
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _T.slate100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _T.slate200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            logoBytes != null
                                ? Image.memory(logoBytes!, fit: BoxFit.contain)
                                : Icon(
                                  Icons.image_outlined,
                                  size: 26,
                                  color: _T.slate300,
                                ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: onPickLogo,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _T.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _T.slate200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.upload_outlined,
                                    size: 13,
                                    color: _T.slate600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    logoBytes != null
                                        ? 'Replace logo'
                                        : 'Upload logo',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _T.slate700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (logoBytes != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: onRemoveLogo,
                              child: Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _T.slate400,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _T.slate300,
                                ),
                              ),
                            ),
                          ],
                          if (logoFileName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              logoFileName!,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _T.slate400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _T.slate100),

            _SettingsRow(
              label: 'Company name',
              child: _InlineField(
                controller: companyNameCtrl,
                placeholder: 'Acme Corporation',
              ),
            ),
            _SettingsRow(
              label: 'Company address',
              hint: 'Printed in document header',
              divider: false,
              child: _InlineField(
                controller: companyAddressCtrl,
                maxLines: 4,
                placeholder: 'Street\nCity\nPostcode\nCountry',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
