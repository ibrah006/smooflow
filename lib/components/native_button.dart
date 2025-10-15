import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NativeButton extends StatelessWidget {
  final Function() onPressed;
  final Widget child;

  /// Only for iOS
  final Widget? trailingAction;

  final BoxDecoration? decoration;

  @Deprecated(
    "This will be completely removed in newer versions, so that this component would only be a native-only button component",
  )
  final bool hasNativeFunctionality;

  const NativeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.trailingAction,
    this.decoration,
    this.hasNativeFunctionality = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        (decoration?.borderRadius as BorderRadius?) ??
        BorderRadius.circular(30);

    if (hasNativeFunctionality && Platform.isIOS) {
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          CupertinoButton(
            onPressed: onPressed,
            borderRadius: borderRadius,
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
        borderRadius: borderRadius,
        child: Ink(
          padding: EdgeInsets.symmetric(
            vertical: 3,
            horizontal: 15,
          ).copyWith(right: 5),
          decoration:
              decoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey.shade100,
              ),
          child: Row(
            children: [
              Expanded(child: child),
              if (trailingAction != null) trailingAction!,
            ],
          ),
        ),
      );
    }
  }
}
