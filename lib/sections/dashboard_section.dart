import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooflow/components/project_card.dart';
import 'package:smooflow/constants.dart';

class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        spacing: 15,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Active Projects", style: textTheme.titleMedium),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Text("View All"),
                    Icon(CupertinoIcons.arrow_right),
                  ],
                ),
              ),
            ],
          ),
          ProjectCard(
            title: "Job Title",
            subtitle: "Sub title",
            status: "Status",
            statusColor: colorPositiveStatus,
            dueDate: "Sep 25",
            progress: 0.75,
            members: [],
          ),
        ],
      ),
    );
  }
}
