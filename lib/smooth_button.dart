import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SmoothButton extends StatefulWidget {
  const SmoothButton({super.key});

  @override
  State<SmoothButton> createState() => _SmoothButtonState();
}

class _SmoothButtonState extends State<SmoothButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _colorAnimation = ColorTween(
      begin: Colors.blue.withOpacity(0.05),
      end: Colors.blue.withOpacity(.15),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.mediumImpact(); // haptic feedback
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorAnimation.value ?? Colors.blue.withOpacity(0.05),
              ),
              padding: const EdgeInsets.all(16.0),
              child: const Icon(
                Icons.notifications,
                color: Colors.blue,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}
