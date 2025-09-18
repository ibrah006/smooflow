import 'package:flutter/material.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        "title": "Production",
        "due": "Due Sep 21, 12:00 AM",
        "completed": true,
        "alert": true,
      },
      {
        "title": "Design",
        "due": "Due Sep 22, 12:00 AM",
        "completed": false,
        "alert": false,
      },
      {
        "title": "Finishing",
        "due": "Due Sep 22, 12:00 AM",
        "completed": false,
        "alert": false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return TimelineStep(
            isFirst: index == 0,
            isLast: index == steps.length - 1,
            title: step["title"] as String,
            due: step["due"] as String,
            completed: step["completed"] as bool,
            alert: step["alert"] as bool,
          );
        },
      ),
    );
  }
}

class TimelineStep extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final String title;
  final String due;
  final bool completed;
  final bool alert;

  const TimelineStep({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.title,
    required this.due,
    required this.completed,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Timeline connector
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: Colors.grey.shade300),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle indicator
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: completed ? Colors.blue : Colors.grey.shade200,
                child: Icon(
                  completed ? Icons.check : Icons.circle_outlined,
                  size: 18,
                  color: completed ? Colors.white : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Card content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            due,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (alert)
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {},
                      ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder:
                              (_) => Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text("Assignees: John, Sarah"),
                                    Text("Due: $due"),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.check),
                                      label: const Text("Mark as Completed"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(45),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
