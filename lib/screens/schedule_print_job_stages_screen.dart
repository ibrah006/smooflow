import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/stock_entry_args.dart';
import 'package:smooflow/enums/material_entry_mode.dart';
import 'package:smooflow/models/printer.dart';
import 'package:smooflow/models/stock_transaction.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';

class SchedulePrintJobStagesScreen extends ConsumerStatefulWidget {
  const SchedulePrintJobStagesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SchedulePrintJobStagesScreen> createState() => _SchedulePrintJobStagesScreenState();
}

class _SchedulePrintJobStagesScreenState extends ConsumerState<SchedulePrintJobStagesScreen>
    with SingleTickerProviderStateMixin {
  int _currentStage = 0;
  final int _totalStages = 5;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form data
  String? _selectedProjectId;
  String? _selectedMaterialId;
  String? _selectedStockItemBarcode;
  String? _selectedPrinterId;
  int _runs = 1;
  bool _requiresInstallation = false;
  String? _installationSite;
  int _estimatedDuration = 30; // minutes
  DateTime? _startTime;
  int _priority = 1;
  String _notes = '';

  double _materialQuantity = 0;
  
  bool _isForward = true;

  @deprecated
  bool _isManualMaterialEntry = false;
  // Look up for selected material stock transactions from database
  bool _lookForStockTransactions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _setupAnimations(true);
    _animationController.forward();
  }

  void _setupAnimations(bool forward) {
    _slideAnimation = Tween<Offset>(
      begin: Offset(forward ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStage() {
    if (_validateCurrentStage()) {
      if (_currentStage < _totalStages - 1) {
        _animationController.reset();
        _setupAnimations(true);
        setState(() {
          _currentStage++;
          _isForward = true;
        });
        _animationController.forward();
      } else {
        _submitForm();
      }
    }
  }

  void _previousStage() {
    if (_currentStage > 0) {
      _animationController.reset();
      _setupAnimations(false);
      setState(() {
        _currentStage--;
        _isForward = false;
      });
      _animationController.forward();
    }
  }

  bool _validateCurrentStage() {
    switch (_currentStage) {
      case 0:
        if (_selectedProjectId == null) {
          _showError('Please select a project');
          return false;
        }
        break;
      case 1:
        if (_selectedStockItemBarcode == null) {
          _showError('Please select a Material Item');
          return false;
        } else if (_materialQuantity < 1) {
          _showError('Please set item quantity to be used');
          return false;
        }
        break;
      // case 2:
      //   if (_selectedPrinterId == null) {
      //     _showError('Please select a printer');
      //     return false;
      //   }
      //   if (_runs < 1) {
      //     _showError('Runs must be at least 1');
      //     return false;
      //   }
      //   break;
      case 2:
        // if (_requiresInstallation && (_installationSite == null || _installationSite!.isEmpty)) {
        //   _showError('Please enter installation site');
        //   return false;
        // }
        break;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _submitForm() {
    // TODO: Submit form data to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print job scheduled successfully!'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule Print Job',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentStage(),
                ),
              ),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalStages, (index) {
          final isActive = index == _currentStage;
          final isCompleted = index < _currentStage;
          
          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: isActive ? 32 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              if (index < _totalStages - 1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: 20,
                  height: 2,
                  color: isCompleted
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (_currentStage) {
      case 0:
        return _buildStage1ProjectSelection();
      case 1:
        return _buildStage2MaterialSelection();
      case 2:
        return _buildStage4Installation();
      case 3:
        return _buildStage5Duration();
      case 4:
        return _buildStage6Options();
      case 5:
        // 
      default:
        return const SizedBox();
    }
  }

  // Stage 1: Project Selection
  Widget _buildStage1ProjectSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStageHeader(
          'Select Project',
          'Choose the project this print job belongs to',
        ),
        const SizedBox(height: 24),
        
        // Illustration
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration:  BoxDecoration(
              color: Colors.blueGrey.shade50,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(15),
            child: SvgPicture.asset(
              "assets/icons/no_projects_icon.svg",
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildSectionCard(
          icon: Icons.folder,
          iconColor: const Color(0xFF2563EB),
          title: 'Project',
          child: _buildProjectDropdown(),
        ),
      ],
    );
  }

  Widget _buildProjectDropdown() {
    final projects = ref.watch(projectNotifierProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProjectId,
          hint: const Text(
            'Select a project',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
          items: projects.map((project) {
            return DropdownMenuItem(
              value: project.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    project.client.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedProjectId = value);
          },
        ),
      ),
    );
  }

  Widget _buildMaterialDropdown() {
    final materials = ref.watch(materialNotifierProvider).materials;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMaterialId,
          isExpanded: true,
          hint: Text('Select material type'),
          // decoration: InputDecoration(
          //   enabled: !_lookForStockTransactions,
          //   border: InputBorder.none,
          //   hintText: 'Select material type',
          //   hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
          // ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
          items:
              materials.map((material) {
                return DropdownMenuItem(
                  value: material.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(material.name, style: const TextStyle(fontSize: 15)),
                      Text(
                        "${material.currentStock} ${material.unit}",
                        style: const TextStyle(
                          fontSize: 12,
                          height: 0,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMaterialId = value;
              _selectedStockItemBarcode = null;
              _lookForStockTransactions = true;
            });
          },
          // validator: (value) => value == null ? 'Please select material' : null,
        ),
      ),
    );
  }

  Widget _buildStockItemDropdown() {
    final materials = ref.watch(materialNotifierProvider).materials;

    final selectedMaterial = materials.firstWhere((material)=> material.id == _selectedMaterialId);
    late String selectedMaterialUnit;
    try {
      selectedMaterialUnit = selectedMaterial.unit;
      selectedMaterialUnit = "${selectedMaterialUnit[0].toUpperCase()}${selectedMaterialUnit.substring(1)}";
    } catch(e) {
      selectedMaterialUnit = "Quantity";
    }

    Future<List<StockTransaction>> materialStockTransationsFuture = ref.watch(materialNotifierProvider.notifier).fetchMaterialTransactions(
      selectedMaterial.id,
      checkIsLocalEmpty: true,
      updateState: false,
      type: TransactionType.stockIn
    );
    
    if (_lookForStockTransactions) {
      _lookForStockTransactions = false;
    }

    return FutureBuilder(
      future: materialStockTransationsFuture,
      builder: (context, snapshot) {

        final materialStockTransations = snapshot.data;

        return Column(
          spacing: 15,
          children: [
            if (materialStockTransations == null)
              CardLoading(height: 55, borderRadius: BorderRadius.circular(12))
            else Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                hint: Row(
                  spacing: 8,
                  children: [
                    if (materialStockTransations.isEmpty) Icon(Icons.block_rounded, color: Colors.grey.shade600),
                    Text(materialStockTransations.isEmpty? 'Empty stock' : 'Select item')
                  ],
                ),
                value: _selectedStockItemBarcode,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
                items:
                    materialStockTransations.map((stockTransaction) {
                      return DropdownMenuItem(
                        value: stockTransaction.barcode,
                        child: Text("${selectedMaterial.name}  ${stockTransaction.barcode}", style: const TextStyle(fontSize: 15)),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _selectedStockItemBarcode = value),
                validator: (value) => value == null ? (materialStockTransations.isEmpty? 'Empty stock' : 'Please select item') : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedMaterialUnit,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      _buildIncrementButton(
                        icon: Icons.remove,
                        onPressed: _materialQuantity > 1 ? () => setState(() => _materialQuantity--) : null,
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _materialQuantity.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (materialStockTransations==null) CircularProgressIndicator()
                      else _buildIncrementButton(
                        icon: Icons.add,
                        onPressed: materialStockTransations.isEmpty || _materialQuantity+1 > selectedMaterial.currentStock? null : () {
                          setState(() => _materialQuantity++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (materialStockTransations?.isEmpty?? false) SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  AppRoutes.navigateTo(context, AppRoutes.stockInEntry, arguments: StockEntryArgs.stockIn());
                  setState(() {
                    _lookForStockTransactions = true;
                  });
                },
                child: Text("Add Stock Entry")
              ),
            )
          ],
        );
      }
    );
  }

  // Stage 2: Material Selection
  Widget _buildStage2MaterialSelection() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStageHeader(
          'Scan Material',
          'Scan the barcode on your material to continue',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                value: true,
                groupValue: _isManualMaterialEntry,
                title: Text("Manual"),
                onChanged: (bool? value) {
                  setState(() {
                    // _character = value;
                    _isManualMaterialEntry = true;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                value: false,
                title: Text("Barcode"),
                groupValue: _isManualMaterialEntry,
                onChanged: (bool? value) {
                  setState(() {
                    // _character = value;
                    _isManualMaterialEntry = false;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        if (_isManualMaterialEntry) _buildSectionCard(
          icon: CupertinoIcons.barcode,
          iconColor: colorPrimary,
          title: 'Select Material',
          child: _buildMaterialDropdown(),
        ) else _buildSectionCard(
          icon: CupertinoIcons.barcode,
          iconColor: colorPrimary,
          title: 'Material Barcode',
          child: _buildBarcodeScanner(),
        ),

        const SizedBox(height: 20),
        
        if (_selectedMaterialId != null) ...[
          _buildSectionCard(
            icon: Icons.inventory_outlined,
            iconColor: colorPrimary,
            title: 'Select Item & Quantity',
            child: _buildStockItemDropdown()
          ),
          const SizedBox(height: 16),
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: const Color(0xFF10B981).withOpacity(0.1),
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(
          //       color: const Color(0xFF10B981).withOpacity(0.3),
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       const Icon(
          //         Icons.check_circle_rounded,
          //         color: Color(0xFF10B981),
          //         size: 24,
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             const Text(
          //               'Material Found',
          //               style: TextStyle(
          //                 fontSize: 15,
          //                 fontWeight: FontWeight.w600,
          //                 color: Color(0xFF0F172A),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       IconButton(
          //         icon: const Icon(Icons.close, color: Color(0xFF64748B)),
          //         onPressed: () {
          //           setState(() => _selectedMaterialId = null);
          //         },
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ],
    );
  }

  Widget _buildBarcodeScanner() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && _selectedMaterialId == null) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    setState(() {
                      _selectedMaterialId = code;
                      _selectedStockItemBarcode = null;
                      _lookForStockTransactions = true;
                    });
                  }
                }
              },
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Position barcode within frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stage 3: Printers and Runs
  Widget _buildStage3PrintersAndRuns() {
    final printers = ref.watch(printerNotifierProvider).printers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStageHeader(
          'Printer & Quantity',
          'Select a printer and specify the number of runs',
        ),
        const SizedBox(height: 24),
        
        // Illustration
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black12,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.print_rounded,
              size: 70,
              color: Colors.black54,
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildSectionCard(
          icon: Icons.print,
          iconColor: Colors.black54,
          title: 'Select Printer',
          child: Column(
            children: printers.map((printer) {
              return _buildPrinterOption(printer);
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildSectionCard(
          icon: Icons.layers,
          iconColor: const Color(0xFFF59E0B),
          title: 'Runs / Batches',
          child: _buildRunsField(),
        ),
      ],
    );
  }

  Widget _buildPrinterOption(Printer printer) {
    final isSelected = _selectedPrinterId == printer.id;
    final isAvailable = printer.isActive;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isAvailable
            ? () => setState(() => _selectedPrinterId = printer.id)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB).withOpacity(0.1)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.print,
                  color: isAvailable
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      printer.statusName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunsField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Number of runs',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Row(
            children: [
              _buildIncrementButton(
                icon: Icons.remove,
                onPressed: _runs > 1 ? () => setState(() => _runs--) : null,
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _runs.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _buildIncrementButton(
                icon: Icons.add,
                onPressed: () => setState(() => _runs++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncrementButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: onPressed != null
            ? const Color(0xFF2563EB)
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: Colors.white,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  // Stage 4: Installation
  Widget _buildStage4Installation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStageHeader(
          'Installation Details',
          'Specify if application or installation is required',
        ),
        const SizedBox(height: 24),
        
        // Illustration
        Center(
          child: Container(
            width: 140,
            height: 140,
            padding: EdgeInsets.only(top: 20, bottom: 12, right: 14.25, left: 16),
            decoration: BoxDecoration(
              color: colorPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              "assets/icons/flow.svg",
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildSectionCard(
          icon: Icons.construction,
          iconColor: colorPrimary,
          title: 'Application / Installation',
          child: _buildApplicationToggle(),
        ),
      ],
    );
  }

  Widget _buildApplicationToggle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Requires Installation?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Switch(
                value: _requiresInstallation,
                onChanged: (value) {
                  setState(() {
                    _requiresInstallation = value;
                    if (!value) _installationSite = null;
                  });
                },
                activeColor: const Color(0xFF2563EB),
              ),
            ],
          ),
        ),
        
        if (_requiresInstallation) ...[
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => _installationSite = value,
            decoration: InputDecoration(
              labelText: 'Installation Site / Location',
              hintText: 'Enter site address or location',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
              prefixIcon: const Icon(Icons.location_on, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ],
    );
  }

  // Stage 5: Duration
  Widget _buildStage5Duration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStageHeader(
          'Time Estimates',
          'Set estimated duration and optional start time',
        ),
        const SizedBox(height: 24),
        
        // Illustration
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 70,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildSectionCard(
          icon: Icons.schedule,
          iconColor: const Color(0xFF2563EB),
          title: 'Estimated Duration',
          child: _buildDurationSlider(),
        ),
        
        const SizedBox(height: 16),
        
        _buildSectionCard(
          icon: Icons.calendar_today,
          iconColor: const Color(0xFF10B981),
          title: 'Start Time (Optional)',
          child: _buildStartTimePicker(),
        ),
      ],
    );
  }

  Widget _buildDurationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${_estimatedDuration} minutes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF2563EB),
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  thumbColor: const Color(0xFF2563EB),
                  overlayColor: const Color(0xFF2563EB).withOpacity(0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _estimatedDuration.toDouble(),
                  min: 10,
                  max: 180,
                  divisions: 17,
                  onChanged: (value) {
                    setState(() => _estimatedDuration = value.toInt());
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '10m',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  Text(
                    '3h',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartTimePicker() {
    return InkWell(
      onTap: () async {
        // final date = await showDatePicker(
        //   context: context,
        //   initialDate: DateTime.now(),
        //   firstDate: DateTime.now(),
        //   lastDate: DateTime.now().add(const Duration(days: 365)),
        // );
        
        // if (date != null) {
        //   final time = await showTimePicker(
        //     context: context,
        //     initialTime: TimeOfDay.now(),
        //   );
          
        //   if (time != null) {
        //     setState(() {
        //       _startTime = DateTime(
        //         date.year,
        //         date.month,
        //         date.day,
        //         time.hour,
        //         time.minute,
        //       );
        //     });
        //   }
        // }
        await showBoardDateTimePicker(
          context: context,
          pickerType: DateTimePickerType.datetime, // still shows date + time
          enableDrag: false,
          onChanged: (result) {
            _startTime = result;
          },
          options: BoardDateTimeOptions(
            boardTitle: "Select Schedule",
            // cancel: "Cancel",
            // confirmText: "Confirm",
            pickerMonthFormat: PickerMonthFormat.short,
            pickerSubTitles: BoardDateTimeItemTitles(
              year: "", // hide year by leaving it empty
              month: "Month",
              day: "Day",
              hour: "Hour",
              minute: "Minute",
            ),
          ),
        );
        setState(() {});
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _startTime != null
                    ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year} at ${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}'
                    : 'Schedule for later',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _startTime != null
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // Stage 6: Options
  Widget _buildStage6Options() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStageHeader(
          'Additional Options',
          'Set priority and add optional notes',
        ),
        const SizedBox(height: 24),
        
        // Illustration
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 70,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        _buildSectionCard(
          icon: Icons.flag,
          iconColor: const Color(0xFFEF4444),
          title: 'Priority Level',
          child: _buildPrioritySelector(),
        ),
        
        const SizedBox(height: 16),
        
        _buildSectionCard(
          icon: Icons.notes,
          iconColor: const Color(0xFF6B7280),
          title: 'Notes (Optional)',
          child: _buildNotesField(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    final priorities = ['Low', 'Medium', 'High', 'Urgent'];
    final colors = {
      'Low': const Color(0xFF10B981),
      'Medium': const Color(0xFF3B82F6),
      'High': const Color(0xFFF59E0B),
      'Urgent': const Color(0xFFEF4444),
    };
    
    return Row(
      children: priorities.map((priority) {
        final isSelected = _priority == priorities.indexOf(priority);
        final color = colors[priority]!;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _priority = priorities.indexOf(priority)),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? color : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      priority,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      maxLines: 4,
      onChanged: (value) => _notes = value,
      decoration: InputDecoration(
        hintText: 'Add any additional notes or instructions...',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildStageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            if (_currentStage > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStage > 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _currentStage < _totalStages - 1 ? _nextStage : _scheduleJob,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentStage < _totalStages - 1 ? 'Next' : 'Schedule Job',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleJob() async {

    final project = ref.watch(projectByIdProvider(_selectedProjectId!));
    final material = ref.watch(materialNotifierProvider).materials.firstWhere((mat) => mat.id == _selectedMaterialId);

    final newTask = Task.create(
      name: "${material.name} - ${project!.name}",
      description: _notes,
      dueDate: null,
      assignees: [],
      projectId: _selectedProjectId!,
      productionDuration: _estimatedDuration,
      printerId: _selectedPrinterId,
      materialId: _selectedMaterialId!,
      productionStartTime: _startTime,
        runs: _runs,
      productionQuantity: _materialQuantity,
      priority: _priority,
      stockTransactionBarcode: _selectedStockItemBarcode!
    );

    // await ref.watch(projectNotifierProvider.notifier).createTask(
    //   task: newTask
    // );
    await ref.read(createProjectTaskProvider(newTask));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job scheduled successfully'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}