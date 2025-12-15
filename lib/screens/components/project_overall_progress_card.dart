

import 'package:flutter/material.dart';

// Project Overall Progress Card
class ProjectOverallProgressCard extends StatelessWidget {
  final String? heroKey;

  final Function()? onPressed;
  final EdgeInsetsGeometry? margin;

  const ProjectOverallProgressCard({
    super.key,
    this.heroKey,
    this.onPressed,
    this.margin
  });

  @override
  Widget build(BuildContext context) {

    final child = Padding(
      padding: margin?? EdgeInsets.zero,
      child: MaterialButton(
        onPressed: onPressed,
        child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.assessment_rounded,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Progress',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '4 of 6 stages completed',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '67%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (onPressed != null) ...[
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded)
                    ]
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 0.67,
                    backgroundColor: Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
      ),
    );

    return heroKey!=null? Hero(
      tag: heroKey!,
      child: child
    ) : child;
  }
}