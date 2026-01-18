import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/components/product_barcode.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';

import 'package:smooflow/utils/exportBarcodeToJpg.dart';

class MaterialStockTransactionsScreen extends ConsumerStatefulWidget {
  final String materialId;

  const MaterialStockTransactionsScreen({Key? key, required this.materialId})
    : super(key: key);

  @override
  ConsumerState<MaterialStockTransactionsScreen> createState() =>
      _StockTransactionsScreenState();
}

class _StockTransactionsScreenState
    extends ConsumerState<MaterialStockTransactionsScreen> {
  String _selectedFilter = 'All';

  List<StockTransaction> get _transactions =>
      ref.watch(materialNotifierProvider).byMaterial(widget.materialId);

  late final MaterialModel material;

  Future<Member> getTransactionCreatedBy(String transactionCreatedById) => ref
      .watch(memberNotifierProvider.notifier)
      .getMemberById(transactionCreatedById);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .watch(materialNotifierProvider.notifier)
          .getMaterialById(widget.materialId)
          .then((value) {
            material = value;
            setState(() {});
          });

      ref
          .watch(materialNotifierProvider.notifier)
          .fetchMaterialTransactions(widget.materialId);
    });
  }

  List<StockTransaction> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      return _transactions;
    } else if (_selectedFilter == 'Stock In') {
      return _transactions
          .where((t) => t.type == TransactionType.stockIn)
          .toList();
    } else {
      return _transactions
          .where((t) => t.type == TransactionType.stockOut)
          .toList();
    }
  }

  int get _stockInCount =>
      _transactions.where((t) => t.type == TransactionType.stockIn).length;
  int get _stockOutCount =>
      _transactions.where((t) => t.type == TransactionType.stockOut).length;

  double get _totalStockIn => _transactions
      .where((t) => t.type == TransactionType.stockIn)
      .fold(0, (sum, t) => sum + t.quantity);

  double get _totalStockOut => _transactions
      .where((t) => t.type == TransactionType.stockOut)
      .fold(0, (sum, t) => sum + t.quantity);

  @override
  Widget build(BuildContext context) {
    try {
      material;
    } catch (e) {
      // Not initialized yet
      return LoadingOverlay(isLoading: true, child: SizedBox());
    }

    return LoadingOverlay(
      isLoading: ref.watch(materialNotifierProvider).isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                material.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Stock transactions',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.black),
              onPressed: () {
                _showMaterialDetails(material);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Material Info Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF4461F2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${material.currentStock} ${material.unit}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              material.currentStock <= material.minStockLevel
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          material.currentStock <= material.minStockLevel
                              ? 'Low Stock'
                              : 'Good',
                          style: TextStyle(
                            color:
                                material.currentStock <= material.minStockLevel
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: const Color(0xFFF5F6FA)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  color: Color(0xFF4CAF50),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_totalStockIn.toStringAsFixed(1)} ${material.unit}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Total Stock In',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFF5F6FA),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                  color: Color(0xFFE53935),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_totalStockOut.toStringAsFixed(1)} ${material.unit}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Total Stock Out',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip('All', _transactions.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Stock In', _stockInCount),
                  const SizedBox(width: 8),
                  _buildFilterChip('Stock Out', _stockOutCount),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transactions List
            Expanded(
              child:
                  _filteredTransactions.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4461F2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.white.withOpacity(0.3)
                          : const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(StockTransaction transaction) {
    final isStockIn = transaction.type == TransactionType.stockIn;
    final timeAgo = _getTimeAgo(transaction.createdAt);

    final color = isStockIn? Color(0xFF4CAF50) : (transaction.committed? Color(0xFFE53935) : colorPending);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showTransactionDetails(transaction);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isStockIn ? Icons.arrow_upward : Icons.arrow_downward,
                        color:
                            color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isStockIn ? 'Stock In' : (transaction.committed? 'Stock Out' : 'Queued'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${isStockIn ? '+' : (transaction.committed? '-' : '')}${transaction.quantity} ${material.unit}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Balance after transaction
                    Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          color: Color(0xFF666666),
                          size: 19,
                        ),
                        Text(
                          ' ${transaction.balanceAfter} ${material.unitShort}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (transaction.barcode != null ||
                    transaction.notes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // if (transaction.projectName != null) ...[
                        //   Row(
                        //     children: [
                        //       const Icon(
                        //         Icons.folder_outlined,
                        //         size: 14,
                        //         color: Color(0xFF4461F2),
                        //       ),
                        //       const SizedBox(width: 6),
                        //       Text(
                        //         'Project: ${transaction.projectName}',
                        //         style: const TextStyle(
                        //           fontSize: 12,
                        //           fontWeight: FontWeight.w500,
                        //           color: Color(0xFF4461F2),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ],
                        if (transaction.barcode != null) ...[
                          // if (transaction.projectName != null)
                          //   const SizedBox(height: 6),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 1.7,
                                child: const Icon(
                                  CupertinoIcons.barcode_viewfinder,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Text(
                                'Barcode: ${transaction.barcode}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (transaction.notes != null) ...[
                          if (
                          // transaction.projectName != null ||
                          transaction.barcode != null)
                            const SizedBox(height: 6),
                          Text(
                            transaction.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    FutureBuilder(
                      future: getTransactionCreatedBy(transaction.createdById),
                      builder: (context, snapshot) {
                        final member = snapshot.data;

                        if (member == null) {
                          return CardLoading(
                            height: 15,
                            width: 70,
                            borderRadius: BorderRadius.circular(10),
                            margin: EdgeInsets.only(top: 2),
                          );
                        }

                        return Text(
                          // transaction.created
                          'By ${member.name}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showTransactionDetails(StockTransaction transaction) {
    final GlobalKey _barcodeKey = GlobalKey();

    final project =
        transaction.projectId != null
            ? ref.watch(projectByIdProvider(transaction.projectId!))
            : null;

    final taskFuture = transaction.taskId!=null? ref.watch(taskByIdProvider(transaction.taskId!)) : null;

    print("transaction taskid: ${transaction.taskId}");

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
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                if (transaction.barcode != null) ...[
                  RepaintBoundary(
                    key: _barcodeKey,
                    child: ProductBarcode(barcode: transaction.barcode!),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildDetailRow(
                  'Type',
                  transaction.type == TransactionType.stockIn
                      ? 'Stock In'
                      : 'Stock Out',
                ),
                _buildDetailRow(
                  'Quantity',
                  '${transaction.quantity} ${material.unit}',
                ),
                _buildDetailRow(
                  'Balance After',
                  '${transaction.balanceAfter} ${material.unit}',
                ),
                // if (transaction.projectName != null)
                //   _buildDetailRow('Project', transaction.projectName!),
                if (transaction.notes != null &&
                    transaction.notes!.trim().isNotEmpty)
                  _buildDetailRow('Notes', transaction.notes!),
                FutureBuilder(
                  future: getTransactionCreatedBy(transaction.createdById),
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
                  '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year} ${transaction.createdAt.hour}:${transaction.createdAt.minute.toString().padLeft(2, '0')}',
                ),
                if (project != null) _buildDetailRow('Project', project.name),
                if (project != null)
                  _buildDetailRow('Client', project.client.name),
                const SizedBox(height: 10),
                if (transaction.type == TransactionType.stockIn)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        exportToJpg(context, _barcodeKey);
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
                      label: Text("Barcode"),
                    ),
                  ),
                if (transaction.taskId != null) FutureBuilder(
                  future: taskFuture,
                  builder: (context, snapshot) {
                    final task = snapshot.data;

                    return task==null? CardLoading(
                        height: 10,
                        borderRadius: BorderRadius.circular(10),
                        margin: EdgeInsets.only(bottom: 5),
                    ) : _buildDetailRow('Job', task.name);
                  }
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4461F2),
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
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      exportToJpg(context, _barcodeKey);
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
                    label: Text("Barcode"),
                  ),
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

  Widget _buildMaterialCard(MaterialModel material) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to material details or stock transactions
            _showMaterialDetails(material);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          if (material.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              material.description!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        material.unit,
                        style: const TextStyle(
                          color: colorPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Stock',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${material.currentStock} ${material.unit}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (material.isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Color(0xFFE53935),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Low',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
