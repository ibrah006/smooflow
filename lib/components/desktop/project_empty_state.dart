// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE COMPONENT
// Shows when there are no tasks for the selected project/filter
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// Design tokens (adjust to match your _T class)
class _T {
  static const blue       = Color(0xFF2563EB);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const slate50    = Color(0xFFF8FAFC);
  static const slate100   = Color(0xFFF1F5F9);
  static const slate200   = Color(0xFFE2E8F0);
  static const slate300   = Color(0xFFCBD5E1);
  static const slate400   = Color(0xFF94A3B8);
  static const slate500   = Color(0xFF64748B);
  static const ink        = Color(0xFF0F172A);
  static const ink3       = Color(0xFF334155);
  static const white      = Colors.white;
  static const r          = 8.0;
  static const rLg        = 12.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class ProjectEmptyState extends StatefulWidget {
  final String? projectName;
  final VoidCallback? onCreateTask;
  final VoidCallback? onClearFilters;
  final bool hasActiveFilters;

  const ProjectEmptyState({
    super.key,
    this.projectName,
    this.onCreateTask,
    this.onClearFilters,
    this.hasActiveFilters = false,
  });

  @override
  State<ProjectEmptyState> createState() => _ProjectEmptyStateState();
}

class _ProjectEmptyStateState extends State<ProjectEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _scaleIn = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Center(
          child: ScaleTransition(
            scale: _scaleIn,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Illustration
                  _EmptyStateIllustration(),
                  const SizedBox(height: 32),

                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.hasActiveFilters
                            ? 'No matching tasks'
                            : widget.projectName != null
                                ? 'No tasks in'
                                : 'No tasks yet',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: _T.ink,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                      Text(
                        !widget.hasActiveFilters && widget.projectName != null
                                ? ' ${widget.projectName}'
                                : '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _T.ink,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    widget.hasActiveFilters
                        ? 'Try adjusting your filters or search terms to find what you\'re looking for.'
                        : widget.projectName != null
                            ? 'Create your first design task to get started with this project.'
                            : 'Start by creating a new design task for your team.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: _T.slate500,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  if (widget.hasActiveFilters && widget.onClearFilters != null)
                    _EmptyStateButton(
                      label: 'Clear Filters',
                      icon: Icons.filter_alt_off_rounded,
                      onTap: widget.onClearFilters!,
                      isPrimary: false,
                    )
                  else if (widget.onCreateTask != null)
                    _EmptyStateButton(
                      label: 'Create First Task',
                      icon: Icons.add_rounded,
                      onTap: widget.onCreateTask!,
                      isPrimary: true,
                    ),

                  // Help text
                  if (!widget.hasActiveFilters && widget.onCreateTask != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _T.slate50,
                            border: Border.all(color: _T.slate200),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_outlined,
                                  size: 14, color: _T.slate400),
                              SizedBox(width: 6),
                              Text(
                                'Or press',
                                style: TextStyle(
                                    fontSize: 12, color: _T.slate400),
                              ),
                              SizedBox(width: 5),
                              _KeyboardKey('N'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyStateButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _EmptyStateButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = true,
  });

  @override
  State<_EmptyStateButton> createState() => _EmptyStateButtonState();
}

class _EmptyStateButtonState extends State<_EmptyStateButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered ? const Color(0xFF1D4ED8) : _T.blue)
                : (_isHovered ? _T.slate100 : _T.white),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: _isHovered ? _T.slate300 : _T.slate200, width: 1.5),
            borderRadius: BorderRadius.circular(_T.rLg),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: _T.blue.withOpacity(_isHovered ? 0.4 : 0.25),
                      blurRadius: _isHovered ? 12 : 8,
                      offset: Offset(0, _isHovered ? 4 : 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isPrimary ? Colors.white : _T.slate500,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: widget.isPrimary ? Colors.white : _T.slate500,
                  letterSpacing: -0.2,
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
// KEYBOARD KEY
// ─────────────────────────────────────────────────────────────────────────────
class _KeyboardKey extends StatelessWidget {
  final String label;
  const _KeyboardKey(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _T.white,
        border: Border.all(color: _T.slate300),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _T.slate500,
          height: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE ILLUSTRATION
// Custom painted illustration with animated elements
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyStateIllustration extends StatefulWidget {
  @override
  State<_EmptyStateIllustration> createState() =>
      _EmptyStateIllustrationState();
}

class _EmptyStateIllustrationState extends State<_EmptyStateIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _T.blue50,
                  _T.slate50,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.blue100, width: 2),
                  ),
                ),
                // Inner content
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.white,
                    boxShadow: [
                      BoxShadow(
                        color: _T.blue.withOpacity(0.08),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Task icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _T.blue50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            size: 28,
                            color: _T.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Dots
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (i) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: _T.slate300,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Floating particles
                Positioned(
                  top: 30,
                  right: 20,
                  child: _FloatingParticle(delay: 0),
                ),
                Positioned(
                  bottom: 40,
                  left: 25,
                  child: _FloatingParticle(delay: 1000),
                ),
                Positioned(
                  top: 60,
                  left: 15,
                  child: _FloatingParticle(delay: 500, size: 6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING PARTICLE
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingParticle extends StatefulWidget {
  final int delay;
  final double size;

  const _FloatingParticle({this.delay = 0, this.size = 8});

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _T.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _T.blue.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USAGE EXAMPLE
// ─────────────────────────────────────────────────────────────────────────────
/*

// In your board view, replace the empty check with this:

if (_visibleTasks.isEmpty) {
  return ProjectEmptyState(
    projectName: _selectedProjectId != null 
        ? _projects.firstWhere((p) => p.id == _selectedProjectId).name 
        : null,
    hasActiveFilters: _filter != TaskFilter.all || _searchQuery.isNotEmpty,
    onCreateTask: _showTaskModal,
    onClearFilters: () {
      setState(() {
        _filter = TaskFilter.all;
        _searchQuery = '';
        _searchCtrl.clear();
      });
    },
  );
}

// Or in list view:
Expanded(
  child: _visibleTasks.isEmpty
      ? ProjectEmptyState(
          projectName: selectedProject?.name,
          onCreateTask: onNewTask,
        )
      : ListView.builder(...),
)

*/