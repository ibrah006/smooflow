import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/screens/desktop_material_details.dart';

class DesktopMaterialListScreen extends ConsumerStatefulWidget {
  const DesktopMaterialListScreen({super.key});

  @override
  ConsumerState<DesktopMaterialListScreen> createState() =>
      _DesktopMaterialListScreenState();
}

class _DesktopMaterialListScreenState
    extends ConsumerState<DesktopMaterialListScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.microtask(() async {
      await ref.watch(materialNotifierProvider.notifier).fetchMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialNotifierProvider).materials;

    return LoadingOverlay(
      isLoading: ref.watch(materialNotifierProvider).isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Materials List"),
          actions: [
            IconButton(
              onPressed: () async {
                await ref
                    .watch(materialNotifierProvider.notifier)
                    .fetchMaterials();
              },
              icon: Icon(Icons.refresh_rounded),
            ),
            SizedBox(width: 10),
          ],
        ),
        body: ListView(
          children:
              materials.map((material) {
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                DesktopMaterialDetails(material: material),
                      ),
                    );
                  },
                  title: Text(material.name),
                  trailing: Text(
                    material.barcode,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
