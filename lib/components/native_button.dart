import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NativeButton extends StatelessWidget {
  final Function() onPressed;
  final Widget child;

  /// Only for iOS
  final Widget? trailingAction;

  const NativeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          CupertinoButton(
            onPressed: onPressed,
            borderRadius: BorderRadius.circular(30),
            color: Colors.grey.shade100,
            padding: EdgeInsets.symmetric(
              vertical: 3 + 10,
              horizontal: 15,
            ).copyWith(right: 5),
            child: Padding(
              padding: EdgeInsets.only(
                // Trailing Action widget's assumed width
                right: 55,
              ),
              child: child,
            ),
          ),
          if (trailingAction != null)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: trailingAction!,
            ),
        ],
      );
    } else {
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: EdgeInsets.symmetric(
            vertical: 3,
            horizontal: 15,
          ).copyWith(right: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.grey.shade100,
          ),
        ),
      );
    }
  }
}
