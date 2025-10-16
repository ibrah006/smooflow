import 'package:flutter/material.dart';

class CustomTabs extends StatelessWidget {
  const CustomTabs({
    super.key,
    required this.selectedTab,
    this.onPressed,
    required this.tabLabels,
    this.hasTabBorder = false,
  });

  final int selectedTab;
  final Function(int tabIndex)? onPressed;

  /// Specify the label and their flex in display
  final Map<String, int> tabLabels;

  final bool hasTabBorder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final commonTextStyle = textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.normal,
      color: Colors.black,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16).copyWith(bottom: 0),
          child: Row(
            spacing: 15,
            children: List.generate(tabLabels.length, (index) {
              final flex = tabLabels.values.elementAt(index);
              final child = LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTap: () {
                      onPressed != null ? onPressed!(index) : null;
                    },
                    child: Column(
                      children: [
                        Text(
                          tabLabels.keys.elementAt(index),
                          style: commonTextStyle.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color:
                                selectedTab != index
                                    ? Colors.grey.shade600
                                    : null,
                          ),
                        ),
                        SizedBox(height: 7),
                        // Selected Indicator
                        Stack(
                          children: [
                            AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              margin: EdgeInsets.symmetric(horizontal: 15),
                              height: selectedTab == index ? 4 : 0,
                              decoration: BoxDecoration(
                                color: Color(0xFF0e55d6),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            SizedBox(height: 4),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
              return Expanded(flex: flex, child: child);
            }),
          ),
        ),
        if (hasTabBorder)
          Divider(height: 1, color: Color.fromARGB(255, 232, 234, 238)),
      ],
    );
  }
}
