import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/product_barcode.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/material.dart';
import 'package:smooflow/models/stock_transaction.dart';
import 'package:smooflow/providers/material_provider.dart';

class StockEntryCheckoutScreen extends ConsumerStatefulWidget {
  final StockTransaction transaction;

  const StockEntryCheckoutScreen(this.transaction, {Key? key})
    : super(key: key);

  @override
  ConsumerState<StockEntryCheckoutScreen> createState() =>
      _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockEntryCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _measureController = TextEditingController();

  MeasureType _selectedMeasureType = MeasureType.running_meter;
  List<MeasureType> get _measureTypes => MeasureType.values.toList();

  bool get isStockIn => widget.transaction.type == TransactionType.stockIn;

  @override
  void dispose() {
    _materialTypeController.dispose();
    _descriptionController.dispose();
    _measureController.dispose();
    super.dispose();
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
                  ProductBarcode(productId: "PRD-1220-233"),

                  const SizedBox(height: 20),

                  // Material Type
                  const Text(
                    'Material Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permanent Vinyl 3.2',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

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
                                  value: _selectedMeasureType,
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
                                controller: _measureController,
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

                  const SizedBox(height: 20),

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
                    'No Description',
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.25,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () async {
                        // Add Stock in/out

                        final materialType =
                            _materialTypeController.text.trim();
                        final description = _descriptionController.text.trim();
                        // Measure / quantity
                        final measure =
                            num.parse(_measureController.text).toDouble();

                        if (_formKey.currentState!.validate()) {
                          // Creates material if it doesn't exist, or returns the existing instance - either from memory or from database
                          final material = await ref
                              .read(materialNotifierProvider.notifier)
                              .createMaterial(
                                MaterialModel.create(
                                  name: materialType,
                                  description: description,
                                  measureType: _selectedMeasureType,
                                ),
                              );

                          // Process stock in/out
                          if (isStockIn) {
                            await ref
                                .read(materialNotifierProvider.notifier)
                                .stockIn(material.id, measure);
                          } else {
                            await ref
                                .read(materialNotifierProvider.notifier)
                                .stockOut(material.id, measure);
                          }
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Stock ${isStockIn ? 'in' : 'out'} Entry added successfully',
                              ),
                            ),
                          );

                          _materialTypeController.clear();
                          _descriptionController.clear();
                          _measureTypes.clear();
                          _measureController.clear();

                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Make sure to fill in all the required inputs',
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isStockIn ? null : colorError,
                        padding: EdgeInsets.all(18),
                        textStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(isStockIn ? 'Add to Stock' : 'Add Stock out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
