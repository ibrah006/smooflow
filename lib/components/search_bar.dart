import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project.dart';
import 'package:smooflow/screens/create_client_screen.dart';

class SearchBar extends ConsumerWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final projects = ref.watch(projectNotifierProvider);

    return InkWell(
      onTap: () {
        showSearch(
          context: context,
          delegate: _MySearchDelegate(
            projects.map((p) => SearchResult<Project>(value: p.name, data: p)),
          ),
        );
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
  final Iterable<SearchResult> items;
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
      icon:
          Platform.isIOS
              ? Icon(Icons.chevron_left, size: 32)
              : Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items.where(
      (item) => item.value.toLowerCase().contains(query.toLowerCase()),
    );

    return ListView(
      children:
          results
              .map(
                (item) => ListTile(
                  title: Text(item.value),
                  // onTap: () => close(context, item.name),
                ),
              )
              .toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final List<SearchResult> suggestions =
        query.toString().isEmpty
            ? []
            : items
                .map((item) {
                  if (item.value.toLowerCase().startsWith(
                    query.toLowerCase(),
                  )) {
                    return item;
                  }
                })
                .whereType<SearchResult>()
                .toList();

    suggestions.addAll(
      List.generate(2, (index) {
        return SearchResult(
          value: ["Create Project", "Add Client"][index],
          data: [Icons.folder_rounded, Icons.person_rounded][index],
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) {
                  switch (index) {
                    case 0:
                      return AddProjectScreen();
                    default:
                      return CreateClientScreen();
                  }
                },
              ),
              (Route<dynamic> route) => route.isFirst,
            );
          },
        );
      }),
    );

    return ListView(
      children:
          suggestions
              .map(
                (item) =>
                    item is SearchResult<Project>
                        ? ListTile(
                          title: Text(
                            item.data.name.toString(),
                            overflow: TextOverflow.fade,
                          ),
                          subtitle:
                              item.data.description != null
                                  ? Text(
                                    item.data.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                  : null,
                          onTap: () {
                            query = item.value;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder:
                                    (context) => AddProjectScreen.view(
                                      projectId: item.data.id,
                                    ),
                              ),
                              (Route<dynamic> route) => route.isFirst,
                            );
                          },
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 12,
                            ),
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
                        )
                        :
                        // add/create action SearchResult
                        ListTile(
                          onTap: item.onPressed,
                          leading: Icon(
                            item.data,
                            color: colorPrimary,
                            size: 29,
                          ),
                          title: Text(item.value),
                        ),
              )
              .toList(),
    );
  }
}

class SearchResult<T> {
  String value;
  T data;

  Function()? onPressed;

  SearchResult({required this.value, required this.data, this.onPressed});
}
