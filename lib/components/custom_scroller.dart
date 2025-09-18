import 'package:flutter/material.dart';

class CustomHorizontalScroller extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;
  final double overlap;
  final ScrollController controller;
  final EdgeInsetsGeometry? padding;

  const CustomHorizontalScroller({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemWidth = 150,
    this.overlap = 30,
    required this.controller,
    this.padding,
  }) : super(key: key);

  @override
  State<CustomHorizontalScroller> createState() =>
      _CustomHorizontalScrollerState();
}

class _CustomHorizontalScrollerState extends State<CustomHorizontalScroller> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollable(
      axisDirection: AxisDirection.right,
      controller: widget.controller,
      physics: const BouncingScrollPhysics(), // or use your own
      viewportBuilder: (context, offset) {
        return Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: Viewport(
            axisDirection: AxisDirection.right,
            offset: offset,
            clipBehavior: Clip.none,
            slivers: [SliverToBoxAdapter(child: _buildCustomContent())],
          ),
        );
      },
    );
  }

  Widget _buildCustomContent() {
    List<Widget> items = [];

    for (int i = 0; i < widget.itemCount; i++) {
      items.add(
        Transform.translate(
          offset: Offset(-i * widget.overlap, 0),
          child: SizedBox(
            width: widget.itemWidth,
            child: widget.itemBuilder(context, i),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200, // adjust height to fit your items
      width:
          widget.itemCount * (widget.itemWidth - widget.overlap) +
          widget.overlap,
      child: Stack(clipBehavior: Clip.none, children: items),
    );
  }
}
