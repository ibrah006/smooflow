import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/models/stock_transaction.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/screens/barcode_export_screen.dart';
import 'package:smooflow/screens/desktop_material_details.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/export_barcodes_args.dart';

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
                    .read(materialNotifierProvider.notifier)
                    .fetchTransactions();

                final transactions =
                    ref.read(materialNotifierProvider).transactions;

                Navigator.pushNamed(
                  context,
                  AppRoutes.barcodeExport,
                  arguments: ExportBarcodesArgs(
                    barcodes: transactions
                        .where((transaction) =>
                            transaction.type == TransactionType.stockIn)
                        .map((transaction) => transaction.barcode!)
                        .toList(),
                  ),
                );
              },
              icon: Icon(Icons.file_upload_rounded),
            ),
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
        body: DataTable2(
          showCheckboxColumn: false,
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 600,
          columns: [
            DataColumn2(label: Text('Material'), size: ColumnSize.L),
            DataColumn2(label: Text('Stock level'), size: ColumnSize.S),
            DataColumn2(label: Text('Unit'), size: ColumnSize.S),
            DataColumn2(label: Text('Barcode'), size: ColumnSize.L),
          ],
          rows:
              materials
                  .map(
                    (material) => DataRow(
                      onSelectChanged: (selected) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.desktopMaterialView,
                          arguments: material,
                        );
                      },
                      cells: [
                        DataCell(Text(material.name)),
                        DataCell(Text(material.currentStock.toString())),
                        DataCell(Text(material.unit)),
                        DataCell(Text(material.barcode)),
                      ],
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
