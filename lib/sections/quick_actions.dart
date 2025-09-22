import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/screens/add_project.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {"icon": Icons.add_rounded, "label": "New Project", "selected": true},
      {
        "icon": Icons.list_alt_rounded,
        "label": "All Projects",
        "selected": false,
      },
      {"icon": Icons.bar_chart_rounded, "label": "Reports", "selected": false},
      {"icon": Icons.settings_rounded, "label": "Settings", "selected": false},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8, // shape ratio like in image
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _GridCard(
          icon: item["icon"] as IconData,
          label: item["label"] as String,
          selected: item["selected"] as bool,
          onPressed: () {
            switch (item["label"]) {
              case "New Project":
            }
          },
        );
      },
    );
  }
}

class _GridCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  @deprecated
  final GestureTapCallback? onPressed;

  const _GridCard({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == "New Project") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProjectScreen()),
          );
        } else if (label == "All Projects") {
          // TODO
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => AddProjectScreen()),
          // );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected ? colorPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBorder, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 30,
                color: selected ? Colors.white : Colors.black87,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
