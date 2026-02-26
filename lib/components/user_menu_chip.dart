// ─────────────────────────────────────────────────────────────────────────────
// user_menu_chip.dart
//
// Drop-in replacement for the static user chip in any topbar.
// Shows a polished popup menu anchored directly below the chip.
//
// Uses CompositedTransformTarget + CompositedTransformFollower so the
// popup tracks the chip perfectly regardless of scroll position.
//
// Usage — replace your existing chip Container with:
//
//   if (user != null)
//     UserMenuChip(
//       user: user,
//       onLogout: () {
//         LoginService.logout();
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (_) => const LoginScreen()),
//           (_) => false,
//         );
//       },
//     )
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/user.dart';
import 'package:smooflow/core/services/login_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — same as every other file in this project
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue     = Color(0xFF2563EB);
  static const blue50   = Color(0xFFEFF6FF);
  static const teal     = Color(0xFF38BDF8);
  static const green    = Color(0xFF10B981);
  static const green50  = Color(0xFFECFDF5);
  static const amber    = Color(0xFFF59E0B);
  static const amber50  = Color(0xFFFEF3C7);
  static const red      = Color(0xFFEF4444);
  static const red50    = Color(0xFFFEE2E2);
  static const slate50  = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink      = Color(0xFF0F172A);
  static const ink3     = Color(0xFF334155);
  static const white    = Colors.white;
  static const r        = 8.0;
  static const rLg      = 12.0;
  static const rXl      = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class UserMenuChip extends StatefulWidget {
  final Function onLogout;

  /// Optional extras to show in the menu above the divider.
  /// Each item: (icon, label, onTap).
  final List<({IconData icon, String label, VoidCallback onTap})>? extraItems;

  const UserMenuChip({
    super.key,
    required this.onLogout,
    this.extraItems,
  });

  @override
  State<UserMenuChip> createState() => _UserMenuChipState();
}

class _UserMenuChipState extends State<UserMenuChip>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;

  User user = LoginService.currentUser!;

  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _ac,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<Offset> _slideAnim = Tween<Offset>(
    begin: const Offset(0, -0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _removeOverlay();
    _ac.dispose();
    super.dispose();
  }

  // ── Overlay management ─────────────────────────────────────────────────────
  void _toggle() {
    if (_open) {
      _close();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    setState(() => _open = true);
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
    _ac.forward(from: 0);
  }

  void _close() async {
    await _ac.reverse();
    _removeOverlay();
    if (mounted) setState(() => _open = false);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Invisible full-screen tap-away catcher
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
          // The menu itself, anchored to the chip
          CompositedTransformFollower(
            link:            _layerLink,
            showWhenUnlinked: false,
            targetAnchor:    Alignment.bottomRight,
            followerAnchor:  Alignment.topRight,
            offset:          const Offset(0, 6),
            child: AnimatedBuilder(
              animation: _ac,
              builder: (_, child) => FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: child,
                ),
              ),
              child: _UserMenu(
                user:       user,
                extraItems: widget.extraItems,
                onClose:    _close,
                onLogout: () async {
                  // _close();
                  // Small delay so the menu closes before navigation
                  // await Future.delayed(const Duration(milliseconds: 180));
                  await widget.onLogout();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            decoration: BoxDecoration(
              color: _open ? _T.slate50 : _T.white,
              border: Border.all(
                color: _open ? _T.slate300 : _T.slate200,
              ),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: _T.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.initials.isNotEmpty ? user.initials[0] : 'A',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _T.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  user.nameShort,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _T.ink3,
                  ),
                ),
                const SizedBox(width: 5),
                // Arrow rotates when open
                AnimatedBuilder(
                  animation: _ac,
                  builder: (_, child) => Transform.rotate(
                    angle: _ac.value * 3.14159, // 0 → π (180°)
                    child: child,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: _T.slate400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POPUP MENU CARD
// ─────────────────────────────────────────────────────────────────────────────
class _UserMenu extends StatefulWidget {
  final User         user;
  final Function() onClose, onLogout;
  final List<({IconData icon, String label, VoidCallback onTap})>? extraItems;

  const _UserMenu({
    required this.user,
    required this.onClose,
    required this.onLogout,
    this.extraItems,
  });

  @override
  State<_UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<_UserMenu> {
  bool _confirmingLogout = false;

  bool _isLogoutLoading = true;

  final user = LoginService.currentUser!;

  @override
  Widget build(BuildContext context) {

    return Material(
      color:       Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rXl),
      child: Container(
        width: 256,
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl),
          border: Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_T.rXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Profile header ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: const BoxDecoration(
                  color: _T.slate50,
                  border: Border(bottom: BorderSide(color: _T.slate200)),
                ),
                child: Row(
                  children: [
                    // Large avatar
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color:       _T.amber.withOpacity(0.15),
                        shape:       BoxShape.circle,
                        border: Border.all(
                          color: _T.amber.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.initials.isNotEmpty
                              ? user.initials.substring(0, user.initials.length.clamp(0, 2))
                              : 'A',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _T.amber,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _T.ink,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _T.slate400,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Role badge row ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _T.amber50,
                      border: Border.all(color: _T.amber.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                            color: _T.amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        user.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: _T.amber,
                        ),
                      ),
                    ]),
                  ),
                  const Spacer(),
                  // Online status
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: _T.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('Online',
                        style: TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w500,
                            color: _T.green)),
                  ]),
                ]),
              ),
              const _Divider(),

              // ── Extra items (optional) ──────────────────────────────
              if (widget.extraItems != null) ...[
                ...widget.extraItems!.map((item) => _MenuItem(
                  icon:    item.icon,
                  label:   item.label,
                  onTap: () {
                    widget.onClose();
                    item.onTap();
                  },
                )),
                const _Divider(),
              ],

              // ── Standard items ──────────────────────────────────────
              _MenuItem(
                icon:  Icons.person_outline_rounded,
                label: 'Profile',
                onTap: widget.onClose, // wire to profile screen
              ),
              _MenuItem(
                icon:  Icons.settings_outlined,
                label: 'Settings',
                onTap: widget.onClose, // wire to settings screen
              ),
              _MenuItem(
                icon:  Icons.keyboard_outlined,
                label: 'Keyboard shortcuts',
                trailing: _KbdBadge('?'),
                onTap: widget.onClose,
              ),
              const _Divider(),

              // ── Logout — with inline confirm state ─────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _confirmingLogout
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: _MenuItem(
                  icon:       Icons.logout_rounded,
                  label:      'Sign out',
                  isDestructive: true,
                  isLoading: _isLogoutLoading,
                  onTap: () => setState(() => _confirmingLogout = true),
                ),
                secondChild: _LogoutConfirmRow(
                  onCancel:  () => setState(() => _confirmingLogout = false),
                  onConfirm: () async {
                    setState(() {
                      _isLogoutLoading = true;
                    });
                    await widget.onLogout();
                    _isLogoutLoading = false;
                  },
                ),
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGOUT CONFIRM ROW — slides in inside the menu
// ─────────────────────────────────────────────────────────────────────────────
class _LogoutConfirmRow extends StatelessWidget {
  final VoidCallback onCancel, onConfirm;
  const _LogoutConfirmRow({required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _T.red50,
          border: Border.all(color: _T.red.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(_T.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: _T.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 13, color: _T.red),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sign out?',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _T.red,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            const Text(
              "You'll need to sign in again to access your workspace.",
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: _T.slate500,
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              // Cancel
              Expanded(
                child: _SmallBtn(
                  label: 'Cancel',
                  onTap:  onCancel,
                  isDestructive: false,
                ),
              ),
              const SizedBox(width: 8),
              // Confirm
              Expanded(
                child: _SmallBtn(
                  label: 'Yes, sign out',
                  onTap:  onConfirm,
                  isDestructive: true,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SmallBtn extends StatefulWidget {
  final String       label;
  final VoidCallback onTap;
  final bool         isDestructive;
  const _SmallBtn({required this.label, required this.onTap, required this.isDestructive});

  @override
  State<_SmallBtn> createState() => _SmallBtnState();
}

class _SmallBtnState extends State<_SmallBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDestructive
        ? (_hovered ? _T.red : _T.red.withOpacity(0.85))
        : (_hovered ? _T.slate100 : _T.white);
    final fg = widget.isDestructive ? _T.white : _T.slate500;
    final border = widget.isDestructive
        ? _T.red.withOpacity(0.5)
        : _T.slate200;

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _MenuItem extends StatefulWidget {
  final IconData   icon;
  final String     label;
  final bool       isDestructive;
  final bool       isLoading;
  final Widget?    trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.isLoading = false,
    this.trailing,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? (widget.isLoading || _hovered ? _T.red : _T.slate500)
        : (_hovered && !widget.isLoading ? _T.ink : _T.slate500);
    final bg = widget.isDestructive && (_hovered || widget.isLoading)
        ? _T.red50
        : _hovered && !widget.isLoading
            ? _T.slate50
            : Colors.transparent;

    return MouseRegion(
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => !widget.isLoading ? setState(() => _hovered = true) : null,
      onExit:  (_) => !widget.isLoading ? setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            // color: bg,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: Row(children: [
            if (widget.isLoading)
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.isLoading? color.withOpacity(0.6) : color),
                ),
              )
            else
              Icon(widget.icon, size: 15, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isLoading? color.withOpacity(0.6) : color,
                ),
              ),
            ),
            if (widget.trailing != null && !widget.isLoading) widget.trailing!,
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KEYBOARD BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _KbdBadge extends StatelessWidget {
  final String key_;
  const _KbdBadge(this.key_);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: _T.slate100,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _T.slate200),
    ),
    child: Text(
      key_,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _T.slate500,
        fontFamily: 'monospace',
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Divider(height: 1, thickness: 1, color: _T.slate100),
  );
}