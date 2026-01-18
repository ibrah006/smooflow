import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/stock_entry_args.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/screens/material_stock_transactions_screen.dart';
import 'package:smooflow/screens/materials_preview_screen.dart';
import 'package:smooflow/screens/stock_entry_screen.dart';

class MaterialsStockScreen extends ConsumerStatefulWidget {
  const MaterialsStockScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MaterialsStockScreen> createState() =>
      _MaterialsStockScreenState();
}

class _MaterialsStockScreenState extends ConsumerState<MaterialsStockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.watch(materialNotifierProvider.notifier).fetchMaterials();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MaterialModel> get _materials =>
      ref.watch(materialNotifierProvider).materials;

  List<MaterialModel> get _filteredMaterials {
    var filtered = _materials;

    // Apply filter
    if (_selectedFilter == 'Low Stock') {
      filtered = filtered.where((m) => m.isLowStock).toList();
    } else if (_selectedFilter == 'Critical') {
      filtered = filtered.where((m) => m.isCriticalStock).toList();
    }

    return filtered;
  }

  int get _lowStockCount => _materials.where((m) => m.isLowStock).length;
  int get _criticalStockCount =>
      _materials.where((m) => m.isCriticalStock).length;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LoadingOverlay(
      isLoading: ref.watch(materialNotifierProvider).isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20).copyWith(bottom: 0),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Platform.isIOS
                                ? Icons.arrow_back_ios
                                : Icons.arrow_back,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Materials Stock',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorPrimary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFFB0B0B0),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: colorPrimary,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.inventory_2,
                      iconColor: colorPrimary,
                      title: '${_materials.length}',
                      subtitle: 'Total Materials',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: colorPending,
                      title: '$_lowStockCount',
                      subtitle: 'Low Stock',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.error_outline,
                      iconColor: colorError,
                      title: '$_criticalStockCount',
                      subtitle: 'Critical',
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', _materials.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Low Stock', _lowStockCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Critical', _criticalStockCount),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Materials List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .watch(materialNotifierProvider.notifier)
                      .fetchMaterials();
                },
                child: _filteredMaterials.isEmpty? ListView(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  children: [
                    SizedBox(
                      height:
                          MediaQuery.of(context).size.height / 30,
                    ),
                    SvgPicture.asset(
                      "assets/icons/no_projects_icon.svg",
                    ),
                    Text(
                      "No Materials",
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(),
                    Text(
                      "Import your existing Materials and Stock data or start a manual entry",
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium!.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Import CSV
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _showImportCSVEducationDialog,
                        child: Text("Import CSV"),
                      ),
                    ),
                    // Stock Enty
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          AppRoutes.navigateTo(context, AppRoutes.stockInEntry, arguments: StockEntryArgs.stockIn());
                        },
                        child: Text("Stock Entry"),
                      ),
                    ),
                    SizedBox(height: kToolbarHeight)
                  ],
                ) : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredMaterials.length,
                  itemBuilder: (context, index) {
                    final material = _filteredMaterials[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _filteredMaterials.length - 1 ? 45 : 0,
                      ),
                      child: _buildMaterialCard(material),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        // floatingActionButton: FloatingActionButton.extended(
        //   onPressed: () {
        //     // Navigate to Stock In screen
        //   },
        //   backgroundColor: colorPrimary,
        //   icon: const Icon(Icons.add, color: Colors.white),
        //   label: const Text(
        //     'Stock In',
        //     style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        //   ),
        // ),
        floatingActionButton: _filteredMaterials.isEmpty? null : Column(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: _showImportCSVEducationDialog,
              backgroundColor: Colors.white,
              heroTag: 'import_csv',
              icon: const Icon(Icons.upload_file, color: colorPrimary),
              label: const Text(
                'Import CSV',
                style: TextStyle(
                  color: colorPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FloatingActionButton.extended(
              onPressed: () {
                // Navigate to Stock In screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockEntryScreen.stockin(),
                  ),
                );
              },
              backgroundColor: colorPrimary,
              heroTag: 'stock_in',
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Stock Entry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
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
          color: isSelected ? colorPrimary : Colors.white,
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

  Widget _buildMaterialCard(MaterialModel material) {
    Color statusColor = colorPositiveStatus;
    String statusText = 'Good';

    if (material.isCriticalStock) {
      statusColor = const Color(0xFFE53935);
      statusText = 'Critical';
    } else if (material.isLowStock) {
      statusColor = const Color(0xFFFF9800);
      statusText = 'Low';
    }

    final title =
        "${material.name[0].toUpperCase()}${material.name.substring(1)}";

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
            // Navigate to material details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MaterialStockTransactionsScreen(
                      materialId: material.id,
                    ),
              ),
            );
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
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            material.description?.toString() ??
                                "No description",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
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
                    Container(
                      width: 1,
                      height: 30,
                      color: const Color(0xFFE5E5E5),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Min Level',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${material.minStockLevel} ${material.unit}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
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

  // import CSV File

  void _showImportCSVEducationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.upload_file,
                      color: colorPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Import Materials from CSV',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CSV Format Requirements:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRequirementRow('name', 'Required', true),
                        _buildRequirementRow(
                          'measure type',
                          'Required',
                          true,
                          subtitle:
                              'running_meter, item_quantity, liters, kilograms, square_meter',
                        ),
                        _buildRequirementRow('description', 'Optional', false),
                        _buildRequirementRow(
                          'min stock level',
                          'Optional (default: 0)',
                          false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFB800)),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFFFB800),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Column names are case-insensitive and can be in any order',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE5E5E5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickCSVFile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Choose File',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildRequirementRow(
    String field,
    String requirement,
    bool isRequired, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color:
                  isRequired
                      ? const Color(0xFFE53935)
                      : const Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      field,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· $requirement',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCSVFile() async {
    // try {
    // Pick CSV file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty) {
      return; // User cancelled
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorPrimary),
            ),
          ),
    );

    // Read file
    final file = File(result.files.single.path!);
    final csvString = await file.readAsString();

    // Parse CSV
    final List<List<dynamic>> csvData = const CsvToListConverter().convert(
      csvString,
      eol: '\n',
      shouldParseNumbers: false,
    );

    if (csvData.isEmpty) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showErrorDialog('Empty CSV', 'The CSV file is empty.');
      return;
    }

    // Parse and validate materials
    final parsedMaterials = await _parseCSVData(csvData);

    await ref
        .watch(materialNotifierProvider.notifier)
        .createMaterials(parsedMaterials);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (parsedMaterials.isEmpty) {
      _showErrorDialog(
        'No Valid Materials',
        'No valid materials found in the CSV file.',
      );
      return;
    }

    // Navigate to preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MaterialsPreviewScreen(materials: parsedMaterials),
      ),
    );
    // } catch (e) {
    //   if (!mounted) return;
    //   Navigator.pop(context); // Close loading if open
    //   _showErrorDialog(
    //     'Import Error',
    //     'Failed to import CSV file: ${e.toString()}',
    //   );
    // }
  }

  Future<List<MaterialModel>> _parseCSVData(List<List<dynamic>> csvData) async {
    final List<MaterialModel> materials = [];
    final List<String> errors = [];

    // Get headers (first row) and normalize them
    final headers =
        csvData[0].map((h) => h.toString().toLowerCase().trim()).toList();

    // Find column indices
    final nameIndex = _findColumnIndex(headers, ['name']);
    final descriptionIndex = _findColumnIndex(headers, ['description', 'desc']);
    final measureTypeIndex = _findColumnIndex(headers, [
      'measure type',
      'measuretype',
      'measure_type',
      'type',
    ]);
    final currentStockIndex = _findColumnIndex(headers, [
      'current stock',
      'currentstock',
      'current_stock',
      'stock',
    ]);
    final minStockIndex = _findColumnIndex(headers, [
      'min stock level',
      'minstocklevel',
      'min_stock_level',
      'min stock',
      'minstock',
      'min_stock',
      'minimum stock',
    ]);

    // Validate required columns
    if (nameIndex == -1) {
      _showErrorDialog(
        'Missing Column',
        'Required column "name" not found in CSV file.',
      );
      return [];
    }

    if (measureTypeIndex == -1) {
      _showErrorDialog(
        'Missing Column',
        'Required column "measure type" not found in CSV file.',
      );
      return [];
    }

    // Process data rows (skip header)
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];

      // Skip empty rows
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }

      try {
        // Extract name (required)
        final name = _getCellValue(row, nameIndex)?.trim();
        if (name == null || name.isEmpty) {
          errors.add('Row ${i + 1}: Name is required');
          continue;
        }

        // Extract measure type (required)
        final measureTypeStr =
            _getCellValue(row, measureTypeIndex)?.toLowerCase().trim();
        if (measureTypeStr == null || measureTypeStr.isEmpty) {
          errors.add('Row ${i + 1}: Measure type is required');
          continue;
        }

        final measureType = _parseMeasureType(measureTypeStr);
        if (measureType == null) {
          errors.add(
            'Row ${i + 1}: Invalid measure type "$measureTypeStr". Valid options: running_meter, item_quantity, liters, kilograms, square_meter',
          );
          continue;
        }

        // Extract optional fields
        final description = _getCellValue(row, descriptionIndex)?.trim();

        final currentStockStr = _getCellValue(row, currentStockIndex)?.trim();
        final currentStock =
            currentStockStr != null && currentStockStr.isNotEmpty
                ? double.tryParse(currentStockStr) ?? 0.0
                : 0.0;

        final minStockStr = _getCellValue(row, minStockIndex)?.trim();
        final minStockLevel =
            minStockStr != null && minStockStr.isNotEmpty
                ? double.tryParse(minStockStr) ?? 0.0
                : 0.0;

        // Validate numeric values
        if (currentStock < 0) {
          errors.add('Row ${i + 1}: Current stock cannot be negative');
          continue;
        }

        if (minStockLevel < 0) {
          errors.add('Row ${i + 1}: Min stock level cannot be negative');
          continue;
        }

        // Create material
        materials.add(
          MaterialModel.create(
            name: name,
            description: description,
            measureType: measureType,
            minStockLevel: minStockLevel,
          ),
        );
      } catch (e) {
        errors.add('Row ${i + 1}: ${e.toString()}');
      }
    }

    // Show errors if any
    if (errors.isNotEmpty && mounted) {
      _showValidationErrorsDialog(errors);
    }

    return materials;
  }

  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      final index = headers.indexWhere((h) => h == name);
      if (index != -1) return index;
    }
    return -1;
  }

  String? _getCellValue(List<dynamic> row, int index) {
    if (index == -1 || index >= row.length) return null;
    final value = row[index];
    return value?.toString();
  }

  MeasureType? _parseMeasureType(String value) {
    final normalized = value.replaceAll(' ', '_').toLowerCase();
    switch (normalized) {
      case 'running_meter':
      case 'runningmeter':
      case 'running meter':
        return MeasureType.running_meter;
      case 'item_quantity':
      case 'itemquantity':
      case 'item quantity':
      case 'quantity':
        return MeasureType.item_quantity;
      case 'liters':
      case 'liter':
      case 'l':
        return MeasureType.liters;
      case 'square_meter':
      case 'squaremeter':
      case 'square meter':
      case 'sqm':
        return MeasureType.square_meter;
      case 'kilograms':
      case 'kilogram':
      case 'kg':
        return MeasureType.kilograms;
      default:
        return null;
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Color(0xFFE53935),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showValidationErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF9800),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Validation Warnings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${errors.length} row${errors.length > 1 ? 's' : ''} could not be imported:',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: errors.length > 5 ? 5 : errors.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: Color(0xFFE53935),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errors[index],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (errors.length > 5) ...[
                    const SizedBox(height: 8),
                    Text(
                      '... and ${errors.length - 5} more',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
