import 'package:flutter/material.dart';
import 'package:smooflow/notifiers/stream/event_notifier.dart';
import 'package:smooflow/screens/desktop/accounts_management_screen.dart';

const _kLeftPaddingDescriptionColumn = 22.0;
const _kLineColumnVerticalDividerHeight = 66.0;
// Increase (_kLineColumnVerticalDividerHeight) by 14 for every line (> 1) for description text in line item
const _kLineColumnVerticalDividerHeightDescriptionMultiplier = 15.0;
const _kLineColumnVerticalPadding = 17.0;
final _kTableDividerColor = Colors.grey.shade200;

class BillingDocumentView extends StatelessWidget {
  final List<QuotationLineItem> lineItems;

  const BillingDocumentView({super.key, required this.lineItems});

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
                        Text("600.00"),
                        Text("5.00%"),
                        Text(
                          "AED ${(600 + (600 * 0.05)).toStringAsFixed(2)}",
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
                      "AED ${(600 + (600 * 0.05)).toStringAsFixed(2)}",
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
                  border: Border(
                    bottom: BorderSide(color: _kTableDividerColor),
                  ),
                )
                : null,
        child: StreamBuilder(
          stream: descriptionLineCountNotifier.stream,
          builder: (context, asyncSnapshot) {
            final descLines = asyncSnapshot.data ?? 1;

            final dividerHeight =
                _kLineColumnVerticalDividerHeight +
                (_kLineColumnVerticalDividerHeightDescriptionMultiplier *
                    (descLines - 1));

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VertDivider(height: dividerHeight),
                Container(
                  width: 35,
                  padding: EdgeInsets.symmetric(
                    vertical: _kLineColumnVerticalPadding,
                  ),
                  child: Center(child: Text("${widget.index}")),
                ),
                VertDivider(height: dividerHeight),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: _kLineColumnVerticalPadding,
                    ).copyWith(left: _kLeftPaddingDescriptionColumn),
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
                      vertical: _kLineColumnVerticalPadding,
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
                      vertical: _kLineColumnVerticalPadding,
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
                      vertical: _kLineColumnVerticalPadding,
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
  const TableHeader({super.key});

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
                  left: _kLeftPaddingDescriptionColumn,
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
    return Container(
      height: height ?? 27,
      width: 1,
      color: _kTableDividerColor,
    );
  }
}
