import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/product_barcode.dart';

import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/stock_transaction.dart';

class StockEntryDetailsScreen extends ConsumerStatefulWidget {
  final StockTransaction transaction;
  final String materialType;
  final MeasureType measureType;

  @Deprecated("for stock out, temporary")
  /// only for stock out
  final String? barcode;

  const StockEntryDetailsScreen(
    this.transaction, {
    Key? key,
    required this.materialType,
    required this.measureType,
    required this.barcode,
  }) : super(key: key);

  @override
  ConsumerState<StockEntryDetailsScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockEntryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final String _description;
  late final double _measure;

  List<MeasureType> get _measureTypes => MeasureType.values.toList();

  bool get isStockIn => widget.transaction.type == TransactionType.stockIn;

  @override
  void initState() {
    super.initState();

    _description = widget.transaction.notes?.toString() ?? "No Description";
    _measure = widget.transaction.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${isStockIn ? 'Stock In' : 'Stock out'} Transaction',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  // Info Card
                  ProductBarcode(
                    barcode:
                        widget.barcode ?? widget.transaction.barcode.toString(),
                  ),

                  const SizedBox(height: 30),

                  // Material Type
                  const Text(
                    'Material Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.materialType,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 23),

                  // Measure Type and Quantity Row
                  Row(
                    children: [
                      // Measure Typer
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Measure Type',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFF5F6FA).withValues(alpha: .6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFE5E5E5,
                                  ).withValues(alpha: .6),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<MeasureType>(
                                  value: widget.measureType,
                                  isExpanded: true,
                                  icon: SizedBox(),
                                  items:
                                      _measureTypes.map((MeasureType type) {
                                        final measureType = type.name
                                            .replaceAll("_", " ")
                                            .split(' ') // split into words
                                            .map(
                                              (word) =>
                                                  word.isNotEmpty
                                                      ? word[0].toUpperCase() +
                                                          word
                                                              .substring(1)
                                                              .toLowerCase()
                                                      : '',
                                            )
                                            .join(' ');
                                        return DropdownMenuItem<MeasureType>(
                                          value: type,
                                          child: Text(
                                            measureType,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Quantity
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E5E5),
                                ),
                              ),
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: _measure.toString(),
                                ),
                                enabled: false,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFB0B0B0),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 13,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Action Buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.symmetric(
                  horizontal: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 20,
              ).copyWith(bottom: 35),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.all(18),
                    textStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text("Done"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
