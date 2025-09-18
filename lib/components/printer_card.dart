import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PrinterCard extends StatelessWidget {
  final String printerName;
  final String role;
  final String incharge;

  const PrinterCard({
    super.key,
    required this.printerName,
    required this.role,
    required this.incharge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Colors.white,
        color: Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 8,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            printerName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Printer icon
          // const Icon(Icons.print, size: 50, color: Colors.black87),
          Align(
            alignment: Alignment.center,
            child: Transform.scale(
              scaleX: 1.4,
              child: SvgPicture.asset("assets/icons/printer.svg", width: 100),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            role,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            incharge,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
