import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooflow/constants.dart';

class CustomButton extends StatefulWidget {
  final VoidCallback onPressed;
  late final Widget child;

  final double? width, height;

  late final EdgeInsetsGeometry? padding;

  final Color? backgroundColor;

  final Color surfaceAnimationColor;

  late final double? borderRadius;

  CustomButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.surfaceAnimationColor = colorPrimary,
  }) {
    isIconButton = false;
  }

  late final IconData icon;

  late final bool isIconButton;

  late final double iconSize;
  late final Color iconColor;

  CustomButton.icon({
    required this.icon,
    required this.onPressed,
    this.width = 45,
    this.height = 45,
    this.backgroundColor,
    this.surfaceAnimationColor = colorPrimary,
    this.iconSize = 28,
    this.iconColor = colorPrimary,
  }) {
    isIconButton = true;
    padding = null;
  }

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _concave;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _concave = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget get _getChild {
    try {
      return Icon(widget.icon, size: widget.iconSize, color: widget.iconColor);
    } catch (e) {
      // regular button with child property
      return widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _concave,
        builder: (context, child) {
          return Container(
            padding: widget.padding,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.isIconButton ? BoxShape.circle : BoxShape.rectangle,
              borderRadius:
                  !widget.isIconButton && widget.borderRadius != null
                      ? BorderRadius.circular(widget.borderRadius!)
                      : null,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  widget.backgroundColor ?? colorLight, // flat base
                  Color.lerp(
                    widget.backgroundColor ?? colorLight,
                    widget.surfaceAnimationColor.withValues(alpha: .2),
                    _concave.value,
                  )!,
                ],
                stops: [0.3 - (_concave.value * 0.2), 1.0],
              ),
            ),
            child: _getChild,
          );
        },
      ),
    );
  }
}
