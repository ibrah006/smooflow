import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project.dart';

class SearchBar extends ConsumerWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final projects = ref.watch(projectNotifierProvider);

    return InkWell(
      onTap: () {
        showSearch(context: context, delegate: _MySearchDelegate(projects));
      },
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              "Search",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _MySearchDelegate extends SearchDelegate<String> {
  final Iterable<Project> items;
  _MySearchDelegate(this.items);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Platform.isIOS ? Icon(Icons.chevron_left) : Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items.where(
      (item) => item.name.toLowerCase().contains(query.toLowerCase()),
    );

    return ListView(
      children:
          results
              .map(
                (item) => ListTile(
                  title: Text(item.name),
                  onTap: () => close(context, item.name),
                ),
              )
              .toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suggestions =
        query.toString().isEmpty
            ? []
            : items
                .map((item) {
                  if (item.name.toLowerCase().startsWith(query.toLowerCase())) {
                    return item;
                  }
                })
                .whereType<Project>()
                .toList();

    print("suggestions: ${suggestions}");

    return ListView(
      children:
          suggestions
              .map(
                (item) => ListTile(
                  title: Text(
                    item.name.toString(),
                    overflow: TextOverflow.fade,
                  ),
                  subtitle:
                      item.description != null
                          ? Text(
                            item.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                          : null,
                  onTap: () {
                    query = item.name;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AddProjectScreen.view(projectId: item.id),
                      ),
                      (Route<dynamic> route) => route.isFirst,
                    );
                  },
                  trailing: Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "Project",
                      style: textTheme.labelMedium!.copyWith(
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}
