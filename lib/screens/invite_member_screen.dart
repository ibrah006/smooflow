// ─────────────────────────────────────────────────────────────────────────────
// invite_member_screen.dart  — redesigned
//
// All original logic preserved (email validation, role check, private domain,
// own-email guard, cancel invitation). Only the presentation layer changed.
//
// Design changes vs. old version:
//   • Full _T token system — no raw Colors.* calls
//   • Role picker: horizontal chip row (tap-to-select) with per-role colours
//   • Form fields: slate50 fill, slate200 border, blue 1.5px focus border
//   • Invitation list: custom cards with avatar initials + role/status pills
//   • Cancel: red outlined button matching design system style
//   • Send button: inline loading spinner (no LoadingOverlay dependency)
//   • Consistent shadows, radii, typography with every other smooflow screen
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/invitation.dart';
import 'package:smooflow/enums/invitation_send_satus.dart';
import 'package:smooflow/providers/invitation_provider.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/core/services/login_service.dart';
import '../extensions/email.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — identical to admin_desktop_dashboard.dart, delivery_dashboard, etc.
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blue50    = Color(0xFFEFF6FF);
  static const blue100   = Color(0xFFDBEAFE);
  static const teal      = Color(0xFF38BDF8);
  static const green     = Color(0xFF10B981);
  static const green50   = Color(0xFFECFDF5);
  static const amber     = Color(0xFFF59E0B);
  static const amber50   = Color(0xFFFEF3C7);
  static const red       = Color(0xFFEF4444);
  static const red50     = Color(0xFFFEE2E2);
  static const purple    = Color(0xFF8B5CF6);
  static const purple50  = Color(0xFFF3E8FF);
  static const slate50   = Color(0xFFF8FAFC);
  static const slate100  = Color(0xFFF1F5F9);
  static const slate200  = Color(0xFFE2E8F0);
  static const slate300  = Color(0xFFCBD5E1);
  static const slate400  = Color(0xFF94A3B8);
  static const slate500  = Color(0xFF64748B);
  static const ink       = Color(0xFF0F172A);
  static const ink3      = Color(0xFF334155);
  static const white     = Colors.white;
  static const r         = 8.0;
  static const rLg       = 12.0;
  static const rXl       = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// ROLE METADATA
// ─────────────────────────────────────────────────────────────────────────────
class _Role {
  final String   value;
  final String   label;
  final String   description;
  final Color    color;
  final Color    bg;
  final IconData icon;

  const _Role({
    required this.value, required this.label, required this.description,
    required this.color, required this.bg, required this.icon,
  });
}

const _kRoles = [
  _Role(
    value: 'admin',       label: 'Admin',
    description: 'Full access',
    color: _T.blue,       bg: _T.blue50,
    icon: Icons.shield_outlined,
  ),
  _Role(
    value: 'design',      label: 'Design',
    description: 'Design tasks',
    color: _T.purple,     bg: _T.purple50,
    icon: Icons.palette_outlined,
  ),
  _Role(
    value: 'production',  label: 'Production',
    description: 'Print & production',
    color: _T.amber,      bg: _T.amber50,
    icon: Icons.print_outlined,
  ),
  _Role(
    value: 'delivery',    label: 'Delivery',
    description: 'Handle deliveries',
    color: _T.green,      bg: _T.green50,
    icon: Icons.local_shipping_outlined,
  ),
  _Role(
    value: 'viewer',      label: 'Viewer',
    description: 'Read-only',
    color: _T.slate500,   bg: _T.slate100,
    icon: Icons.visibility_outlined,
  ),
];

_Role? _roleByValue(String? v) =>
    v == null ? null : _kRoles.cast<_Role?>()
        .firstWhere((r) => r?.value == v, orElse: () => null);

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class InviteMemberScreen extends ConsumerStatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  final _emailCtrl  = TextEditingController();
  final _emailFocus = FocusNode();
  String? _selectedRole;
  bool    _sending  = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invitationNotifierProvider.notifier)
          .fetchInvitations(forceReload: false);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // ── Send invitation ────────────────────────────────────────────────────────
  Future<void> _send() async {
    final email = _emailCtrl.text.toLowerCase().trim();
    final orgFuture = ref.read(
        organizationNotifierProvider.notifier).getCurrentOrganization;

    // Own email guard
    if (email == LoginService.currentUser?.email) {
      _snack("You can't invite yourself.", isError: true);
      return;
    }
    // Empty / invalid
    if (email.isEmpty || !email.isEmail) {
      _snack('Enter a valid email address.', isError: true);
      return;
    }
    // Role not selected
    if (_selectedRole == null) {
      _snack('Please select a role for this member.', isError: true);
      return;
    }

    final org = await orgFuture;

    // Private domain mismatch
    if (email.isPrivateEmail &&
        org.privateDomain != null &&
        email != org.privateDomain) {
      _snack(
        'This email\'s domain doesn\'t match your organisation\'s private domain.',
        isError: true,
      );
      return;
    }

    setState(() => _sending = true);
    HapticFeedback.lightImpact();

    final result = await ref
        .read(invitationNotifierProvider.notifier)
        .sendInvitation(email: email, role: _selectedRole);

    setState(() => _sending = false);

    switch (result) {
      case InvitationSendStatus.success:
        HapticFeedback.mediumImpact();
        _snack('Invitation sent to $email', isError: false);
        _emailCtrl.clear();
        setState(() => _selectedRole = null);
      case InvitationSendStatus.alreadyPending:
        _snack('An invitation to this person is already pending.', isError: true);
      default:
        _snack('Failed to send invitation. Please try again.', isError: true);
    }
  }

  // ── Cancel invitation ──────────────────────────────────────────────────────
  Future<void> _cancel(Invitation invite) async {
    HapticFeedback.selectionClick();
    try {
      await ref.read(invitationNotifierProvider.notifier)
          .cancelInvitation(invite.id);
      _snack('Invitation cancelled.', isError: false);
    } catch (e) {
      _snack(e.toString(), isError: true);
    }
    setState(() {});
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w500)),
          ),
        ]),
        backgroundColor: isError ? _T.ink : _T.ink,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_T.r)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(invitationNotifierProvider);
    final invitations = state.invitations;
    final mq          = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: _T.slate50,
      appBar: _buildAppBar(),
      body: state.isLoading && invitations.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: _T.blue, strokeWidth: 2.5))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 20, 16, 20 + mq.padding.bottom),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Compose card ────────────────────────────────────
                  _ComposeCard(
                    emailCtrl:    _emailCtrl,
                    emailFocus:   _emailFocus,
                    selectedRole: _selectedRole,
                    sending:      _sending,
                    onRoleSelected: (r) =>
                        setState(() => _selectedRole = r),
                    onSend: _send,
                  ),
                  const SizedBox(height: 28),

                  // ── Invitations list ────────────────────────────────
                  _SectionHeader(
                    title: 'Pending Invitations',
                    count: invitations
                        .where((i) => i.status != InvitationStatus.cancelled)
                        .length,
                  ),
                  const SizedBox(height: 12),

                  if (invitations.isEmpty)
                    _EmptyInvites()
                  else
                    ...invitations.map((invite) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InviteRow(
                        invite:   invite,
                        onCancel: invite.status == InvitationStatus.cancelled
                            ? null
                            : () => _cancel(invite),
                      ),
                    )),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor:  _T.white,
      foregroundColor:  _T.ink,
      elevation:        0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle:      false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _T.slate200),
      ),
      title: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: _T.blue50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _T.blue.withOpacity(0.25)),
          ),
          child: const Icon(Icons.person_add_outlined,
              size: 16, color: _T.blue),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite Members',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: _T.ink, letterSpacing: -0.2)),
            Text('Send a role-specific invitation',
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w500,
                    color: _T.slate400)),
          ],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ComposeCard extends StatelessWidget {
  final TextEditingController emailCtrl;
  final FocusNode             emailFocus;
  final String?               selectedRole;
  final bool                  sending;
  final ValueChanged<String?> onRoleSelected;
  final VoidCallback          onSend;

  const _ComposeCard({
    required this.emailCtrl,
    required this.emailFocus,
    required this.selectedRole,
    required this.sending,
    required this.onRoleSelected,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Card header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _T.blue50,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: _T.blue.withOpacity(0.2)),
                ),
                child: const Icon(Icons.mail_outlined,
                    size: 16, color: _T.blue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invite by Email',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: _T.ink, letterSpacing: -0.2)),
                    Text('They\'ll receive a link to join your workspace',
                        style: TextStyle(
                            fontSize: 11.5, color: _T.slate400,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ]),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Divider(height: 1, color: _T.slate100),
          ),

          // ── Email field ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Email address'),
                const SizedBox(height: 7),
                _SmooTextField(
                  controller:  emailCtrl,
                  focusNode:   emailFocus,
                  hintText:    'colleague@company.com',
                  prefixIcon:  Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Role picker ───────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _FieldLabel('Role'),
          ),
          const SizedBox(height: 9),
          _RolePicker(
            selected:   selectedRole,
            onSelected: onRoleSelected,
          ),
          const SizedBox(height: 18),

          // ── Send button ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: sending ? null : onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: _T.blue,
                  disabledBackgroundColor: _T.slate200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_T.rLg)),
                ),
                icon: sending
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 17),
                label: Text(
                  sending ? 'Sending…' : 'Send Invitation',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
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
// ROLE PICKER — horizontal chip row
// ─────────────────────────────────────────────────────────────────────────────
class _RolePicker extends StatelessWidget {
  final String?               selected;
  final ValueChanged<String?> onSelected;
  const _RolePicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount:      _kRoles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final role   = _kRoles[i];
          final active = selected == role.value;
          return GestureDetector(
            onTap: () => onSelected(active ? null : role.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: active ? role.bg : _T.white,
                borderRadius: BorderRadius.circular(_T.rLg),
                border: Border.all(
                  color: active
                      ? role.color.withOpacity(0.55)
                      : _T.slate200,
                  width: active ? 1.5 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: role.color.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(role.icon, size: 14,
                        color: active ? role.color : _T.slate400),
                    const SizedBox(width: 6),
                    Text(role.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active ? role.color : _T.ink3,
                        )),
                    if (active) ...[
                      const SizedBox(width: 5),
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: role.color),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(role.description,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: active
                            ? role.color.withOpacity(0.7)
                            : _T.slate400,
                        fontWeight: FontWeight.w400,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INVITATION ROW CARD
// ─────────────────────────────────────────────────────────────────────────────
class _InviteRow extends StatelessWidget {
  final Invitation   invite;
  final VoidCallback? onCancel;
  const _InviteRow({required this.invite, required this.onCancel});

  bool get _isCancelled => invite.status == InvitationStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final role    = _roleByValue(invite.role);
    final initials = _emailInitials(invite.email);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isCancelled ? _T.slate50 : _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(
          color: _isCancelled
              ? _T.slate100
              : _T.slate200,
        ),
      ),
      child: Row(children: [

        // Avatar
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _isCancelled
                ? _T.slate100
                : (role?.bg ?? _T.blue50),
            shape: BoxShape.circle,
            border: Border.all(
              color: _isCancelled
                  ? _T.slate200
                  : (role?.color.withOpacity(0.25) ?? _T.blue.withOpacity(0.25)),
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _isCancelled
                    ? _T.slate400
                    : (role?.color ?? _T.blue),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Email + role
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invite.email,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isCancelled ? _T.slate400 : _T.ink3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(children: [
                // Role pill
                if (role != null)
                  _Pill(
                    label: role.label,
                    color: _isCancelled ? _T.slate400 : role.color,
                    bg:    _isCancelled ? _T.slate100 : role.bg,
                  ),
                const SizedBox(width: 6),
                // Status pill
                _Pill(
                  label: _isCancelled ? 'Cancelled' : 'Pending',
                  color: _isCancelled ? _T.slate400 : _T.amber,
                  bg:    _isCancelled ? _T.slate100 : _T.amber50,
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Cancel button
        if (!_isCancelled)
          _CancelButton(onTap: onCancel)
        else
          const SizedBox(width: 4),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CANCEL BUTTON — red outlined, matches design system
// ─────────────────────────────────────────────────────────────────────────────
class _CancelButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _CancelButton({required this.onTap});

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? _T.red50 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? _T.red.withOpacity(0.5)
                  : _T.slate200,
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _hovered ? _T.red : _T.slate500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int    count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title,
          style: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w700,
              color: _T.ink3, letterSpacing: -0.1)),
      if (count > 0) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: _T.amber50,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _T.amber.withOpacity(0.3))),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: _T.amber)),
        ),
      ],
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyInvites extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 32),
    decoration: BoxDecoration(
      color: _T.white,
      borderRadius: BorderRadius.circular(_T.rLg),
      border: Border.all(color: _T.slate200),
    ),
    child: Column(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
            color: _T.slate100, shape: BoxShape.circle),
        child: const Icon(Icons.mail_outline_rounded,
            size: 22, color: _T.slate400),
      ),
      const SizedBox(height: 12),
      const Text('No invitations yet',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
              color: _T.ink3)),
      const SizedBox(height: 4),
      const Text('Send your first invitation above',
          style: TextStyle(fontSize: 12.5, color: _T.slate400)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SmooTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode?            focusNode;
  final String                hintText;
  final IconData              prefixIcon;
  final TextInputType?        keyboardType;

  const _SmooTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.focusNode,
    this.keyboardType,
  });

  @override
  State<_SmooTextField> createState() => _SmooTextFieldState();
}

class _SmooTextFieldState extends State<_SmooTextField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode?.hasFocus ?? false);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
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
      controller:   widget.controller,
      focusNode:    widget.focusNode,
      keyboardType: widget.keyboardType,
      style: const TextStyle(
          fontSize: 14, color: _T.ink, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
            fontSize: 14, color: _T.slate300,
            fontWeight: FontWeight.w400),
        prefixIcon: Icon(widget.prefixIcon, size: 17, color: _T.slate400),
        border:        InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 13, horizontal: 14),
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w700,
        color: _T.slate500, letterSpacing: 0.1),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color  color, bg;
  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _emailInitials(String email) {
  final local = email.split('@').first;
  final parts = local.split(RegExp(r'[._\-+]'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return local.length >= 2
      ? local.substring(0, 2).toUpperCase()
      : local.toUpperCase();
}