import 'package:flutter/material.dart';
// import 'package:smooflow/components/overlap_card_scroll.dart';
import 'package:smooflow/components/stacked_card.scroll.dart';
import 'package:smooflow/components/printer_card.dart';

class PrintersDashboardSection extends StatelessWidget {
  const PrintersDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // OverlapCardScroll(),
        StackedSnapList(
          itemCount: 6,
          itemBuilder:
              (context, index) => PrinterCard(
                printerName: "Print Machine ##${index + 1}",
                role: "Printer",
                incharge: "Ali Yusuf",
              ),
        ),
        // SingleChildScrollView(
        //   scrollDirection: Axis.horizontal,
        //   child: Stack(
        //     children: List.generate(5, (index) {
        //       return Padding(
        //         padding: EdgeInsets.only(left: (index + 1) * 100),
        //         child: PrinterCard(
        //           printerName: "Printer Machine ###",
        //           role: "Production Head",
        //           incharge: "Ali Yusuf",
        //         ),
        //       );
        //     }),
        //   ),
        // ),
      ],
    );
  }
}
