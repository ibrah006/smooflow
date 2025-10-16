import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';

class ProjectDetailsSensitiveActions extends StatelessWidget {
  const ProjectDetailsSensitiveActions({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SizedBox(height: 15),
          Text(
            "Sensitive Actions",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
