import 'package:flutter/material.dart';
import 'package:smooflow/components/sections/project_timeline_section.dart';

class ProductionProjectArgs {
  final String projectId;
  ProductionProjectArgs({Key? key, required this.projectId});

  final GlobalKey<ProjectTimelineMilestonesSectionState>
  projectTimelineMilestoneSectionKey = GlobalKey();
}
