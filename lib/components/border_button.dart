import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BorderButton extends StatefulWidget {
  const BorderButton({
    super.key,
    this.child,
    this.onPressed,
    this.margin,
    this.padding,
  });

  final Widget? child;
  final Function? onPressed;
  final EdgeInsetsGeometry? margin, padding;

  @override
  State<BorderButton> createState() => _BorderButtonState();
}

class _BorderButtonState extends State<BorderButton> {
  bool clicked = false;

  static const clickAnimationDuration = Duration(milliseconds: 150);

  click() async {
    setState(() {
      clicked = true;
    });
    await Future.delayed(clickAnimationDuration);
    setState(() {
      clicked = false;
    });

    if (widget.onPressed != null) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: click,
        child: AnimatedContainer(
          duration: clickAnimationDuration,
          padding: widget.padding ?? EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: clicked ? 0 : 1.25,
              color: Color(0xFFeef5fc),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
