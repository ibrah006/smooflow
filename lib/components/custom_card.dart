import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  const CustomCard(
      {super.key,
      this.child,
      this.alignment,
      this.color,
      this.hasShadow = true,
      this.margin,
      this.onPressed,
      this.padding,
      this.borderRadius = 16,
      this.shadowGreyLevel = 0.04,
      this.strokeWidth,
      this.height,
      this.width});

  final Widget? child;
  final AlignmentGeometry? alignment;
  final Color? color;
  final bool hasShadow;
  final EdgeInsetsGeometry? margin, padding;
  final Function? onPressed;
  final double borderRadius;
  final double shadowGreyLevel;
  final double? strokeWidth;
  final double? width, height;

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool isPressedDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onPressed != null ? widget.onPressed!() : null;
      },
      // onTapDown: (details) {
      //   setState(() {
      //     isPressedDown = true;
      //   });
      //   widget.onPressed != null ? widget.onPressed!() : null;
      // },
      // onTapUp: (details) {
      //   setState(() {
      //     isPressedDown = false;
      //   });
      // },
      // onTapCancel: () {
      //   setState(() {
      //     isPressedDown = false;
      //   });
      // },
      // onPanEnd: (details) {
      //   setState(() {
      //     isPressedDown = false;
      //   });
      // },
      onLongPress: () {
        // TODO: Haptic feedback
      },
      onLongPressEnd: (details) {
        setState(() {
          isPressedDown = false;
        });
      },
      child: AnimatedScale(
        scale: isPressedDown ? .95 : 1,
        duration: Duration(milliseconds: 25),
        child: Container(
          height: widget.height,
          width: widget.width,
          margin: widget.margin,
          alignment: widget.alignment,
          padding: widget.padding ?? EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
                color: Color(0xFFe9f1f8), width: widget.strokeWidth ?? 0),
            boxShadow: !widget.hasShadow
                ? null
                : [
                    BoxShadow(
                      color:
                          Colors.grey.withValues(alpha: widget.shadowGreyLevel),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
            color: widget.color ?? Colors.white,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
