import 'package:flutter/widgets.dart';
import 'package:smooflow/core/models/material.dart';

class MaterialsPreviewArgs {
  final List<MaterialModel> materials;
  final Key? key;

  const MaterialsPreviewArgs({this.key, required this.materials});
}
