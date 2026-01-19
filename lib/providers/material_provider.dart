import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/notifiers/material_notifier.dart';
import 'package:smooflow/states/material.dart';
import '../core/repositories/material_repo.dart';

final materialRepoProvider = Provider<MaterialRepo>((ref) => MaterialRepo());

final materialNotifierProvider =
    StateNotifierProvider<MaterialNotifier, MaterialState>(
      (ref) => MaterialNotifier(ref.watch(materialRepoProvider)),
    );
