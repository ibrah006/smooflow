import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/sections/dashboard_section.dart';

class TabSection extends StatefulWidget {
  const TabSection({super.key});

  @override
  State<TabSection> createState() => _TabSectionState();
}

class _TabSectionState extends State<TabSection> {
  final List<Tab> myTabs = [
    Tab(text: 'Dashboard'),
    Tab(text: 'Projects'),
    Tab(text: 'Analytics'),
    Tab(text: 'Team'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: myTabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          toolbarHeight: 10,
          bottom: TabBar(
            tabs: myTabs,
            overlayColor: WidgetStatePropertyAll(Colors.white),
            labelColor: colorPrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: colorPrimary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        body: TabBarView(
          children: [
            _tabContent('Dashboard'),
            _tabContent('Projects Content'),
            _tabContent('Team Content'),
            _tabContent('Reports Content'),
          ],
        ),
      ),
    );
  }

  Widget _tabContent(String title) {
    switch (title) {
      case "Dashboard":
        return DashboardSection();
      default:
        return Text("Unimplemented");
    }
  }
}
