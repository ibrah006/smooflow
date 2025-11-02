import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/material.dart';
import 'package:smooflow/models/stock_transaction.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/screens/barcode_scan_page.dart';
import 'package:smooflow/screens/stock_entry_checkout_screen.dart';

class StockEntryScreen extends ConsumerStatefulWidget {
  late final bool isStockIn;

  StockEntryScreen.stockin({Key? key}) : projectId = null, super(key: key) {
    isStockIn = true;
  }

  late final MaterialModel material;
  late final StockTransaction transaction;
  final String? projectId;

  StockEntryScreen.stockOut({
    Key? key,
    required this.material,
    required this.transaction,
    required this.projectId,
  }) : super(key: key) {
    isStockIn = false;
  }

  @override
  ConsumerState<StockEntryScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _measureController = TextEditingController();

  MeasureType _selectedMeasureType = MeasureType.running_meter;
  List<MeasureType> get _measureTypes => MeasureType.values.toList();

  getMeasureTypeDisplayName(MeasureType type) => type.name
      .replaceAll("_", " ")
      .split(' ') // split into words
      .map(
        (word) =>
            word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '',
      )
      .join(' ');

  @override
  void initState() {
    super.initState();

    if (!widget.isStockIn) {
      _materialTypeController.text = widget.material.name;
      _descriptionController.text =
          widget.transaction.notes ?? "No Description";
      _selectedMeasureType = widget.material.measureType;
    }
  }

  @override
  void dispose() {
    _materialTypeController.dispose();
    _descriptionController.dispose();
    _measureController.dispose();
    super.dispose();
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      // Camera permission granted, proceed with camera functionality
    } else if (status.isDenied) {
      // Camera permission denied
    } else if (status.isRestricted) {
      // Camera permission permanently denied, guide user to app settings
      openAppSettings(); // Opens the app's settings page
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: ref.watch(materialNotifierProvider).isLoading,
      child: Scaffold(
        // backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment:
                Platform.isIOS
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
            children: [
              Text(
                widget.isStockIn ? 'Stock In' : 'Stock out',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Add new inventory to stock',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await requestCameraPermission();
                Navigator.of(context).pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            BarcodeScanScreen(projectId: widget.projectId),
                  ),
                );
              },
              color: !widget.isStockIn ? colorPrimary : colorError,
              icon: Icon(widget.isStockIn ? Icons.upload : Icons.download),
            ),
          ],
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF4461F2),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'A unique barcode will be generated for this stock entry',
                              style: TextStyle(
                                color: Color(0xFF1F1F1F),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Material Information Section
                    const Text(
                      'Material Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isStockIn
                          ? 'Enter material details and specifications'
                          : 'Please input the quantity you want to stock out',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // Material Type
                    Text(
                      'Material Type${widget.isStockIn ? '*' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!widget.isStockIn)
                      Text(
                        _materialTypeController.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: TextFormField(
                          controller: _materialTypeController,
                          decoration: const InputDecoration(
                            hintText: 'Enter material type',
                            hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter material type';
                            }
                            return null;
                          },
                        ),
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
                    if (!widget.isStockIn)
                      Text(
                        _descriptionController.text,
                        style: TextStyle(color: Colors.grey.shade700),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Describe material specifications, color, brand, etc.',
                            hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),

                    if (widget.isStockIn) SizedBox(height: 20),

                    // Measure Type and Quantity Row
                    Row(
                      children: [
                        // Measure Type
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Measure Type${widget.isStockIn ? '*' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!widget.isStockIn)
                                Text(
                                  getMeasureTypeDisplayName(
                                    _selectedMeasureType,
                                  ),
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<MeasureType>(
                                      value: _selectedMeasureType,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.black,
                                      ),
                                      items:
                                          _measureTypes.map((MeasureType type) {
                                            final measureType =
                                                getMeasureTypeDisplayName(type);
                                            return DropdownMenuItem<
                                              MeasureType
                                            >(
                                              value: type,
                                              child: Text(
                                                measureType,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (MeasureType? type) {
                                        if (type != null) {
                                          setState(() {
                                            _selectedMeasureType = type;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Quantity
                        Expanded(
                          flex: widget.isStockIn ? 2 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!widget.isStockIn) SizedBox(height: 27),
                              const Text(
                                'Quantity*',
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
                          final description =
                              _descriptionController.text.trim();
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
                            late final StockTransaction transaction;
                            // try {
                            if (widget.isStockIn) {
                              transaction = await ref
                                  .read(materialNotifierProvider.notifier)
                                  .stockIn(material.id, measure);
                            } else {
                              transaction = await ref
                                  .read(materialNotifierProvider.notifier)
                                  .stockOut(
                                    widget.transaction.barcode!,
                                    measure,
                                    projectId: widget.projectId,
                                  );
                            }
                            // } catch (e) {
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     SnackBar(
                            //       content: Text("Failed: ${e.toString()}"),
                            //     ),
                            //   );
                            //   return;
                            // }

                            // Show stock transaction details page
                            Navigator.of(context).pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => StockEntryDetailsScreen(
                                      transaction,
                                      materialType: materialType,
                                      measureType: _selectedMeasureType,
                                      barcode:
                                          widget.isStockIn
                                              ? null
                                              : widget.transaction.barcode,
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
                          backgroundColor: widget.isStockIn ? null : colorError,
                          padding: EdgeInsets.all(18),
                          textStyle: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(
                          widget.isStockIn ? 'Add to Stock' : 'Add Stock out',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
