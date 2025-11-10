import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/product_barcode.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/material.dart';
import 'package:smooflow/models/member.dart';
import 'package:smooflow/providers/member_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
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
