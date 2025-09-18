import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';

class OverviewCard extends StatelessWidget {
  final Widget icon;
  final String title, value;
  final Color color;

  const OverviewCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon,
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: textTheme.titleSmall!.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
