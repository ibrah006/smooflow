// lib/screens/printer/add_printer_screen.dart
import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/printer.dart';

class AddPrinterScreen extends StatefulWidget {
  final Printer? printer; // null for add, non-null for edit

  const AddPrinterScreen({Key? key, this.printer}) : super(key: key);

  @override
  State<AddPrinterScreen> createState() => _AddPrinterScreenState();
}

class _AddPrinterScreenState extends State<AddPrinterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _locationController;

  PrinterStatus _selectedStatus = PrinterStatus.active;
  List<String> _selectedStaffIds = [];
  Map<String, dynamic> _specifications = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.printer?.name ?? '');
    _nicknameController = TextEditingController(
      text: widget.printer?.nickname ?? '',
    );
    _locationController = TextEditingController(
      text: widget.printer?.location ?? '',
    );

    if (widget.printer != null) {
      _selectedStatus = widget.printer!.status;
      // _selectedStaffIds = widget.printer!.assignedStaffIds ?? [];
      _specifications = {
        "maxWidth": widget.printer!.maxWidth,
        "printSpeed": widget.printer!.printSpeed,
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.printer != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Printer' : 'Add New Printer',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFE53E3E)),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Information Card
            _buildCard(
              title: 'Basic Information',
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Printer Name',
                  hint: 'e.g., Epson SureColor P8000',
                  icon: Icons.print,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter printer name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nicknameController,
                  label: 'Nickname',
                  hint: 'e.g., Large Format A',
                  icon: Icons.badge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a nickname';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location (Optional)',
                  hint: 'e.g., Production Floor - Section A',
                  icon: Icons.location_on,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status & Settings Card
            _buildCard(
              title: 'Status & Settings',
              children: [
                _buildStatusSelector(),
                const SizedBox(height: 16),
                _buildStaffAssignment(),
              ],
            ),

            const SizedBox(height: 16),

            // Specifications Card (Optional)
            _buildCard(
              title: 'Specifications (Optional)',
              children: [
                _buildSpecificationItem('Max Print Width', 'cm'),
                const SizedBox(height: 12),
                _buildSpecificationItem('Max Print Height', 'cm'),
                const SizedBox(height: 12),
                _buildSpecificationItem('Print Speed', 'sqm/hour'),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _savePrinter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add Printer',
                      style: const TextStyle(
                        fontSize: 16,
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
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            prefixIcon: Icon(icon, color: Color(0xFF9CA3AF), size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: colorPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Printer Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              PrinterStatus.values.map((status) {
                final isSelected = _selectedStatus == status;
                return InkWell(
                  onTap: () => setState(() => _selectedStatus = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? _getStatusColor(status).withOpacity(0.1)
                              : const Color(0xFFF9FAFB),
                      border: Border.all(
                        color:
                            isSelected
                                ? _getStatusColor(status)
                                : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected
                                    ? _getStatusColor(status)
                                    : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildStaffAssignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Staff',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showStaffPicker,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF9CA3AF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedStaffIds.isEmpty
                        ? 'Select staff members'
                        : '${_selectedStaffIds.length} staff assigned',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _selectedStaffIds.isEmpty
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF9CA3AF),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificationItem(String label, String unit) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: TextFormField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: unit,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: colorPrimary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.active:
        return const Color(0xFF10B981);
      case PrinterStatus.offline:
        return const Color(0xFF6B7280);
      case PrinterStatus.maintenance:
        return const Color(0xFFF59E0B);
      case PrinterStatus.error:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusLabel(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.active:
        return 'Active';
      case PrinterStatus.offline:
        return 'Offline';
      case PrinterStatus.maintenance:
        return 'Maintenance';
      case PrinterStatus.error:
        return 'Error';
    }
  }

  void _showStaffPicker() {
    // TODO: Implement staff picker dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Assign Staff'),
            content: const Text('Staff picker will be implemented here'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _savePrinter() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement save logic
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.printer != null
                ? 'Printer updated successfully'
                : 'Printer added successfully',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Printer'),
            content: const Text(
              'Are you sure you want to delete this printer? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Printer deleted successfully'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
