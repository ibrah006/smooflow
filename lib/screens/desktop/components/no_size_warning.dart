import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoSizeWarning extends StatelessWidget {
  const NoSizeWarning();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        Icon(Icons.straighten_outlined, size: 10, color: Colors.amber.shade700),
        const SizedBox(width: 4),
        Text(
          'No size specified',
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.amber.shade700,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
