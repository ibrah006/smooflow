import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/material.dart';
import 'package:smooflow/providers/material_provider.dart';

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
                        Icon(
                          Platform.isIOS
                              ? Icons.arrow_back_ios
                              : Icons.arrow_back,
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
                child: ListView.builder(
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

  String getUnit(MeasureType type) {
    switch (type) {
      case MeasureType.running_meter:
        return "meters";
      case MeasureType.item_quantity:
        return "units";
      case MeasureType.kilograms:
        return "kgs";
      case MeasureType.liters:
        MeasureType.liters.name;
      default:
        return "sqm";
    }
    return "";
  }

  Widget _buildMaterialCard(MaterialModel material) {
    Color statusColor = colorPositiveStatus;
    String statusText = 'Good';

    // if (material.isCriticalStock) {
    //   statusColor = const Color(0xFFE53935);
    //   statusText = 'Critical';
    // } else if (material.isLowStock) {
    //   statusColor = const Color(0xFFFF9800);
    //   statusText = 'Low';
    // }

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
                            '${material.currentStock} ${getUnit(material.measureType)}',
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
                            '${material.minStockLevel} ${getUnit(material.measureType)}',
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
}
