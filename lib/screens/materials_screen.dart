import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/providers/material_provider.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _StockEntriesScreenState();
}

class _StockEntriesScreenState extends ConsumerState<MaterialsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.watch(materialNotifierProvider.notifier).fetchMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialNotifierProvider).materials;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.watch(materialNotifierProvider.notifier).fetchMaterials();
        },
        child: ListView(
          children:
              materials.map((material) {
                return FutureBuilder(
                  future: ref
                      .watch(materialNotifierProvider.notifier)
                      .getMaterialById(material.id),
                  builder: (context, materialSnapshot) {
                    return materialSnapshot.data != null
                        ? ListTile(
                          title: Text(materialSnapshot.data!.name),
                          trailing: Text(material.name),
                          onTap: () {},
                        )
                        : CardLoading(height: 65, width: double.infinity);
                  },
                );
              }).toList(),
        ),
      ),
    );
  }
}
