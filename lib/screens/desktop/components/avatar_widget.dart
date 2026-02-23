import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  const AvatarWidget(
      {required this.initials, required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: Center(
          child: Text(initials,
              style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      );
}