import 'package:flutter/material.dart';
import 'package:smooflow/core/models/quotation_line_item.dart';
import 'package:smooflow/notifiers/stream/event_notifier.dart';
import 'package:smooflow/screens/desktop/accounts_management_screen.dart';

const kLeftPaddingDescriptionColumn = 22.0;
const kLineColumnVerticalDividerHeight = 66.0;
// Increase (_kLineColumnVerticalDividerHeight) by 14 for every line (> 1) for description text in line item
const kLineColumnVerticalDividerHeightDescriptionMultiplier = 15.0;
const kLineColumnVerticalPadding = 17.0;
final kTableDividerColor = Colors.grey.shade200;

class Quotation {
  final String id;
  final String projectId;
  List<QuotationLineItem> lineItems;
  QuotationStatus status;
  String notes;
  final DateTime createdAt;
  // incremented label, e.g. "QUO-001"
  final String number;

  double get total => lineItems.fold(0, (s, i) => s + i.amount);

  Quotation({
    required this.id,
    required this.projectId,
    required this.lineItems,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.number,
  });
}

class InvoiceLineItem {
  final String id;
  final int? taskId;
  String description;
  double qty;
  double unitPrice;

  // Snapshot from quotation at time of invoice creation
  final String originalDescription;
  final double originalQty;
  final double originalUnitPrice;

  double get amount => qty * unitPrice;

  bool get descriptionChanged => description != originalDescription;
  bool get qtyChanged => qty != originalQty;
  bool get unitPriceChanged => unitPrice != originalUnitPrice;
  bool get hasAnyChange => descriptionChanged || qtyChanged || unitPriceChanged;

  InvoiceLineItem({
    required this.id,
    this.taskId,
    required this.description,
    required this.qty,
    required this.unitPrice,
    required this.originalDescription,
    required this.originalQty,
    required this.originalUnitPrice,
  });

  /// Creates an InvoiceLineItem from a QuotationLineItem, snapshotting
  /// the current values as originals.
  factory InvoiceLineItem.fromQuotationItem(QuotationLineItem q) =>
      InvoiceLineItem(
        id: '${q.id}',
        taskId: q.taskId,
        description: q.description,
        qty: q.qty,
        unitPrice: q.unitPrice,
        originalDescription: q.description,
        originalQty: q.qty,
        originalUnitPrice: q.unitPrice,
      );
}

class Invoice {
  final String id;
  final String quotationId;
  final String projectId;
  List<InvoiceLineItem> lineItems;
  InvoiceStatus status;
  String notes;
  DateTime? dueDate;
  final DateTime createdAt;
  final String number; // e.g. "INV-001"

  double get total => lineItems.fold(0, (s, i) => s + i.amount);
  double get originalTotal =>
      lineItems.fold(0, (s, i) => s + i.originalQty * i.originalUnitPrice);
  double get totalDelta => total - originalTotal;
  bool get hasChanges => lineItems.any((i) => i.hasAnyChange);

  Invoice({
    required this.id,
    required this.quotationId,
    required this.projectId,
    required this.lineItems,
    required this.status,
    required this.notes,
    required this.dueDate,
    required this.createdAt,
    required this.number,
  });

  /// Creates an Invoice from a Quotation, snapshotting all line items.
  factory Invoice.fromQuotation(Quotation q, String invoiceNumber) => Invoice(
    id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
    quotationId: q.id,
    projectId: q.projectId,
    lineItems: q.lineItems.map(InvoiceLineItem.fromQuotationItem).toList(),
    status: InvoiceStatus.draft,
    notes: q.notes,
    dueDate: DateTime.now().add(const Duration(days: 30)),
    createdAt: DateTime.now(),
    number: invoiceNumber,
  );
}

class BillingDocumentView extends StatelessWidget {
  final List<QuotationLineItem> lineItems;
  final double vatPercentage;

  const BillingDocumentView({
    super.key,
    required this.lineItems,
    required this.vatPercentage,
  });

  double get subTotal =>
      lineItems.map((item) => item.amount).reduce((a, b) => a + b);

  double get total => (subTotal + (subTotal * vatPercentage / 100));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 55, horizontal: 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  child: Icon(
                    Icons.image,
                    size: 45,
                    color: Colors.grey.shade400,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Building No : 2872, Al Kharj Rd",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text("6858 Al Dilaa Dist", style: TextStyle(fontSize: 13)),
                    Text("Riyadh : 14315", style: TextStyle(fontSize: 13)),
                    Text(
                      "Riyadh, Kingdom of Saudi Arabia",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // QUOTE title divider
            Stack(
              alignment: Alignment.center,
              children: [
                Divider(color: Colors.grey.shade200, thickness: 1.3),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    "QUOTE",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Client details & Quote info.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Quote to", style: TextStyle(fontSize: 11.5)),
                    SizedBox(height: 6),
                    Text(
                      "Scott, Melba R.",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "2468 Blackwell Street\nFairbanks\n99701\nUAE",
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ],
                ),
                // Quote info.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text("Quote#:", style: TextStyle(fontSize: 12.55)),
                        Text(
                          " 3501",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text("Date: 24 Mar 2026", style: TextStyle(fontSize: 12.5)),
                    Text(
                      "Terms: Due on Receipt",
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // Table
            TableHeader(),
            // Line items
            ...lineItems.map((item) {
              print("item id: ${item.id}");
              final index = int.parse(item.id);
              return LineItem(
                index: index,
                description: item.description,
                subTitle: item.subTitle,
                quantity: item.qty,
                rate: item.unitPrice,
                isLast: index == lineItems.length,
              );
            }),

            // Billing total & Overview
            DefaultTextStyle(
              style: TextStyle(fontSize: 10.8, color: Colors.black),
              child: Container(
                width: 250,
                decoration: BoxDecoration(color: Color(0xFFf5f3f4)),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 13,
                        children: [
                          Text("Sub Total"),
                          Text("Tax Rate"),
                          Text(
                            "Total",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    // Billing Values
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 13,
                      children: [
                        Text(subTotal.toStringAsFixed(2)),
                        Text("${vatPercentage.toStringAsFixed(2)}%"),
                        Text(
                          "AED ${total.toStringAsFixed(2)}",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Total balance due
            DefaultTextStyle(
              style: TextStyle(fontSize: 10.8, color: Colors.black),
              child: Container(
                width: 250,
                decoration: BoxDecoration(color: Color(0xFFe3f2eb)),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 90,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Balance Due",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Billing Values
                    Text(
                      "AED ${total.toStringAsFixed(2)}",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),

            // Terms & Conditions
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Terms & Conditions",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Full payment is due upon receipt of the invoice.",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LineItem extends StatefulWidget {
  final int index;
  final String description;
  final String? subTitle;
  final double quantity;
  final double rate;
  final bool isLast;

  const LineItem({
    super.key,
    required this.index,
    required this.description,
    required this.subTitle,
    required this.quantity,
    required this.rate,
    this.isLast = false,
  });

  @override
  State<LineItem> createState() => _LineItemState();
}

class _LineItemState extends State<LineItem> {
  int descriptionLineCount = 1;

  EventNotifier<int> descriptionLineCountNotifier = EventNotifier();

  int getLineCount({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final textSpan = TextSpan(text: text, style: style);

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: null,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth);

    return textPainter.computeLineMetrics().length;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      child: Container(
        decoration:
            widget.isLast
                ? BoxDecoration(
                  border: Border(bottom: BorderSide(color: kTableDividerColor)),
                )
                : null,
        child: StreamBuilder(
          stream: descriptionLineCountNotifier.stream,
          builder: (context, asyncSnapshot) {
            final descLines = asyncSnapshot.data ?? 1;

            final dividerHeight =
                kLineColumnVerticalDividerHeight +
                (kLineColumnVerticalDividerHeightDescriptionMultiplier *
                    (descLines - 1));

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VertDivider(height: dividerHeight),
                Container(
                  width: 35,
                  padding: EdgeInsets.symmetric(
                    vertical: kLineColumnVerticalPadding,
                  ),
                  child: Center(child: Text("${widget.index}")),
                ),
                VertDivider(height: dividerHeight),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: kLineColumnVerticalPadding,
                    ).copyWith(left: kLeftPaddingDescriptionColumn, right: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int lines = getLineCount(
                              text: widget.description,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                              maxWidth: constraints.maxWidth,
                            );

                            if (descriptionLineCount != lines) {
                              descriptionLineCount = lines;
                              descriptionLineCountNotifier.sink.add(lines);
                            }

                            return Text(widget.description);
                          },
                        ),
                        if (widget.subTitle != null) ...[
                          SizedBox(height: 2),
                          Text(
                            widget.subTitle!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                VertDivider(height: dividerHeight),
                SizedBox(
                  width: 70,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      vertical: kLineColumnVerticalPadding,
                    ).copyWith(right: 10),
                    child: Text(widget.quantity.toStringAsFixed(2)),
                  ),
                ),
                VertDivider(height: dividerHeight),
                SizedBox(
                  width: 70,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      vertical: kLineColumnVerticalPadding,
                    ).copyWith(right: 10),
                    child: Text(widget.rate.toStringAsFixed(2)),
                  ),
                ),
                VertDivider(height: dividerHeight),
                SizedBox(
                  width: 70,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      vertical: kLineColumnVerticalPadding,
                    ).copyWith(right: 10),
                    child: Text(
                      (widget.quantity * widget.rate).toStringAsFixed(2),
                    ),
                  ),
                ),
                VertDivider(height: dividerHeight),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TableHeader extends StatelessWidget {
  final bool isEditMode;

  const TableHeader({super.key, this.isEditMode = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w300,
      ),
      child: Container(
        color: Color(0xFF179a56),
        child: Row(
          children: [
            VertDivider(),
            SizedBox(width: 35, child: Center(child: Text("#"))),
            VertDivider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric().copyWith(
                  left: kLeftPaddingDescriptionColumn,
                ),
                child: Text("Item & Description"),
              ),
            ),
            VertDivider(),
            SizedBox(
              width: 70,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric().copyWith(right: 10),
                child: Text("Qty"),
              ),
            ),
            VertDivider(),
            SizedBox(
              width: 70,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric().copyWith(right: 10),
                child: Text("Rate"),
              ),
            ),
            VertDivider(),
            SizedBox(
              width: 70,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric().copyWith(right: 10),
                child: Text("Amount"),
              ),
            ),
            VertDivider(),
            if (isEditMode) SizedBox(width: 29),
            VertDivider(),
          ],
        ),
      ),
    );
  }
}

class VertDivider extends StatelessWidget {
  final double? height;
  const VertDivider({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(height: height ?? 27, width: 1, color: kTableDividerColor);
  }
}
