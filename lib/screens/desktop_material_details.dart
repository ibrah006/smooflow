import 'package:card_loading/card_loading.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/components/product_barcode.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/screens/barcode_export_screen.dart';

class DesktopMaterialDetails extends ConsumerStatefulWidget {
  final MaterialModel material;

  const DesktopMaterialDetails({super.key, required this.material});

  @override
  ConsumerState<DesktopMaterialDetails> createState() =>
      _DesktopMaterialDetailsState();
}

class _DesktopMaterialDetailsState
    extends ConsumerState<DesktopMaterialDetails> {
  MaterialModel get material => widget.material;

  List<StockTransaction> get _transactions =>
      ref.watch(materialNotifierProvider).byMaterial(material.id);

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: ref.watch(materialNotifierProvider).isLoading,
      child: Scaffold(
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Material Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RepaintBoundary(
                    key: GlobalKey(),
                    child: ProductBarcode(barcode: material.barcode),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow('Material', material.name),
                  _buildDetailRow('Unit', material.unit),
                  _buildDetailRow(
                    'Quantity',
                    '${material.currentStock} ${material.unit}',
                  ),
                  // if (transaction.projectName != null)
                  //   _buildDetailRow('Project', transaction.projectName!),
                  if (material.description != null &&
                      material.description!.trim().isNotEmpty)
                    _buildDetailRow('Notes', material.description!),
                  // FutureBuilder(
                  //   future: getMaterialCreatedBy(material.createdById),
                  //   builder: (context, snapshot) {
                  //     final member = snapshot.data;

                  //     if (member == null) {
                  //       return CardLoading(
                  //         height: 10,
                  //         borderRadius: BorderRadius.circular(10),
                  //         margin: EdgeInsets.only(bottom: 5),
                  //       );
                  //     }
                  //     return _buildDetailRow('Created By', member.name);
                  //   },
                  // ),
                  _buildDetailRow(
                    'Date',
                    '${material.createdAt.day}/${material.createdAt.month}/${material.createdAt.year} ${material.createdAt.hour}:${material.createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                  SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ExportBarcodesScreen(
                                barcodes:
                                    _transactions
                                        .where(
                                          (transaction) =>
                                              transaction.type ==
                                              TransactionType.stockIn,
                                        )
                                        .map(
                                          (transaction) => transaction.barcode!,
                                        )
                                        .toList(),
                              ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 15,
                      ),
                      side: BorderSide(color: colorPrimary),
                      foregroundColor: colorPrimary,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: Icon(Icons.file_upload_outlined),
                    label: Text("Barcodes"),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Items"),
                      IconButton(
                        onPressed: () async {
                          await ref
                              .watch(materialNotifierProvider.notifier)
                              .fetchMaterialTransactions(material.id);
                        },
                        icon: Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 300,
                      margin: EdgeInsets.only(bottom: 40),
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 300,
                        columns: [
                          DataColumn2(
                            label: Text('Description'),
                            size: ColumnSize.L,
                          ),
                          DataColumn2(
                            label: Text('Stock in'),
                            size: ColumnSize.S,
                          ),
                          DataColumn2(
                            label: Text('Barcode'),
                            size: ColumnSize.S,
                          ),
                        ],
                        rows:
                            _transactions
                                .where(
                                  (transaction) =>
                                      transaction.type ==
                                      TransactionType.stockIn,
                                )
                                .map(
                                  (transaction) => DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          transaction.notes ?? "No Description",
                                          style:
                                              transaction.notes == null
                                                  ? TextStyle(
                                                    color: Colors.grey.shade500,
                                                  )
                                                  : null,
                                        ),
                                      ),
                                      DataCell(
                                        Text("+${transaction.quantity}"),
                                      ),
                                      DataCell(
                                        Text(transaction.barcode.toString()),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Member> getMaterialCreatedBy(String transactionCreatedById) => ref
      .watch(memberNotifierProvider.notifier)
      .getMemberById(transactionCreatedById);

  void _showMaterialDetails(MaterialModel material) {
    final GlobalKey _barcodeKey = GlobalKey();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Material Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                RepaintBoundary(
                  key: _barcodeKey,
                  child: ProductBarcode(barcode: material.barcode),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Material', material.name),
                _buildDetailRow('Unit', material.unit),
                _buildDetailRow(
                  'Quantity',
                  '${material.currentStock} ${material.unit}',
                ),
                // if (transaction.projectName != null)
                //   _buildDetailRow('Project', transaction.projectName!),
                if (material.description != null &&
                    material.description!.trim().isNotEmpty)
                  _buildDetailRow('Notes', material.description!),
                FutureBuilder(
                  future: getMaterialCreatedBy(material.createdById),
                  builder: (context, snapshot) {
                    final member = snapshot.data;

                    if (member == null) {
                      return CardLoading(
                        height: 10,
                        borderRadius: BorderRadius.circular(10),
                        margin: EdgeInsets.only(bottom: 5),
                      );
                    }
                    return _buildDetailRow('Created By', member.name);
                  },
                ),
                _buildDetailRow(
                  'Date',
                  '${material.createdAt.day}/${material.createdAt.month}/${material.createdAt.year} ${material.createdAt.hour}:${material.createdAt.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
