import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smooflow/components/custom_scroller.dart';

class StackedSnapList extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  const StackedSnapList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<StackedSnapList> createState() => _StackedSnapListState();
}

class _StackedSnapListState extends State<StackedSnapList>
    with TickerProviderStateMixin {
  final ScrollController _ctrl = ScrollController();
  double _scroll = 0.0;

  // visual constants
  static const double cardWidth = 175;
  // overlapping offset b/w cards
  static const overlappingOffset = 99.1667;
  static const double overlap = 110; // how much each card overlaps next (tight)
  static const double step = cardWidth - overlap; // effective step per card

  static const double default_scroll_animation_value = 0;

  late final vp;

  bool autoScrolling = false;

  // scroll back animation
  late AnimationController _controller;
  late Animation<double> _animation;

  // the maximum scroll extent
  late final maxExtent;

  late double extentBefore = 0;

  // The cards that are left AFTER scroll extent
  late int cardsExtentAfter;

  // maximum cards that can fit in the viewport
  late final int maxCardsInVP;

  // constant
  int get totalCards => widget.itemCount;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _scroll = _ctrl.offset);
    });

    // set the initial value for cards that are left extentAfter
    cardsExtentAfter = widget.itemCount;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: default_scroll_animation_value,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // You can try Curves.elasticOut, etc.
    );

    _animation.addListener(() {
      // clamp to the nearest while ensuring there are enough cards after extent
      // calculate the extent (pixels) of the maxCardsInViewPort
      // this value is the viewport (vp)

      // and display the last few cards (cards length: max cards in viewport)
      // max extent - viewport extent = last few cards that perfectly fits in the viewport
      // change this
      final extent = maxExtent - vp;

      print("maxExtent: $maxExtent, vp: $vp");

      _ctrl.jumpTo(
        extent,
        // extentBefore * _animation.value,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Last recorded dist for each card
  List<double?> get cardsDist =>
      List.generate(widget.itemCount, (index) => null);

  void _snapToNearest(double viewportWidth) {
    // compute a floating index such that when snapped, the target card's right edge aligns to screen right
    // targetOffset = index*step - (viewportWidth - cardWidth)
    final raw = (_scroll + (viewportWidth - cardWidth)) / step;
    int idx = raw.round().clamp(0, widget.itemCount - 1);
    final target = (idx * step) - (viewportWidth - cardWidth);
    final bounded = target.clamp(0.0, max(0.0, (widget.itemCount - 1) * step));
    // _ctrl.animateTo(
    //   bounded.toDouble(),
    //   duration: const Duration(milliseconds: 360),
    //   curve: Curves.easeOut,
    // );
  }

  @override
  Widget build(BuildContext context) {
    try {
      vp = MediaQuery.of(context).size.width;
    } catch (e) {
      // value already set
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final vw = constraints.maxWidth;
        return NotificationListener<ScrollEndNotification>(
          onNotification: (n) {
            if (autoScrolling) return true;

            // when scroll ends, auto-snap
            // _snapToNearest(vw);

            // 1. find the card selection spot
            // print(
            //   "maxextent: ${n.metrics.maxScrollExtent}, minextent: ${n.metrics.minScrollExtent}\n-----------",
            // );

            // print(
            //   "extentafter: ${n.metrics.extentAfter}, \nextentbefore: ${n.metrics.extentBefore}, \nextentinside: ${n.metrics.extentInside}}",
            // );

            // What's the card's width - 175px, const set in printer card component
            // What's the offset of overlapping between cards - (-99.1666) abs value can be taken for calculation as we're just concerned with the difference

            // estimate the no. of cards that can supposedly fit in the viewport

            // viewport
            // try {
            //   vp = n.metrics.viewportDimension;
            // } catch (e) {
            //   // viewport value already set
            // }

            // no. of cards in the viewport
            // account for selected card width in viewport - selected card width == card width: 175px
            try {
              maxCardsInVP =
                  ((vp - cardWidth) / (cardWidth - overlappingOffset)).floor() +
                  1;
            } catch (e) {
              // Already initialized the constant (final) value
            }

            // cards scrolled past ie., the cards the have gone off the left side of the screen
            final cardsPast =
                (n.metrics.extentBefore / (cardWidth - overlappingOffset))
                    .round();

            try {
              maxExtent = n.metrics.maxScrollExtent;
            } catch (E) {
              // value already set
            }

            extentBefore = n.metrics.extentBefore;

            final extentAfter = n.metrics.extentAfter;

            // // no. of cards that can fit in the extent after
            // // accounting for selected card as well because it lies in the right side of the screen all the time
            cardsExtentAfter =
                ((extentAfter - cardWidth) / (cardWidth - overlappingOffset))
                    .floor() +
                1;

            if ((totalCards - cardsPast) <= maxCardsInVP &&
                n.metrics.axisDirection == AxisDirection.right) {
              print("scroll past thi si forbidden");
              autoScrolling = true;

              // scroll axis direction == right, set scroll animation value = 1 (forwards), as we're about to reverse animate
              _controller.value = 1;

              // auto scroll back
              // this event is going to be listened from animation event listener from the initState and going to notify the scroll view to move to that position
              _controller.reverse().then((value) {
                setState(() {
                  autoScrolling = false;
                });
              });
            }

            print("cards past: ${cardsPast}");

            return true;
          },
          child: SizedBox(
            height: 300,
            child: CustomHorizontalScroller(
              controller: _ctrl,
              // scrollDirection: Axis.horizontal,
              // physics: const BouncingScrollPhysics(),
              itemCount: widget.itemCount,
              padding: EdgeInsets.only(
                right: vw - cardWidth,
              ), // allow last item to align to right edge
              itemBuilder: (context, index) {
                // compute the position of this card's "logical left" in the scroll coordinate
                final cardLeft = index * step;
                final cardCenter = cardLeft + cardWidth / 2;
                // distance from the selected focal position (which is scroll + viewportWidth - cardWidth)
                final focal = _scroll + vw - cardWidth;
                final dist =
                    (cardLeft - focal) /
                    step; // relative distance in card units

                // compute transforms:
                // left-of-selected: negative dist -> stacked and partially visible (~40-50%)
                // selected (dist approx 0): full scale & opacity
                // right-of-selected: positive small (0..1) -> show one card ~80-90%, others offscreen shrink & fade
                double absd = dist.abs();
                // scale: selected ~1.0, neighbors down to 0.75, far right shrink to 0.35
                double scale = (1 - (absd * 0.12)).clamp(0.35, 1.0);
                // opacity: full near selected, fade with distance
                double opacity = 1; //(1 - (absd * 0.7)).clamp(0.0, 1.0);

                cardsDist[index] = dist;

                // For cards far to the right (dist > 1.2) shrink more & fade
                if (dist > 1.2) {
                  scale = 0.35;
                  // opacity = 0.0;
                }

                // Check if this card can be visible on the screen
                // say, x = the position (extent) of this card in the scroll view
                // say, y = scroll extent (current scroll offset) + viewport = offset of last card that can be displayed in the viewport
                // if x> y => don't display this card (or 0.3x scale and 0.3 opacity)

                // x = (cardWidth - overlappingOffset) * (cardIndex + 1) + cardWidth
                // offset of the card
                final cardOffset =
                    (cardWidth - overlappingOffset) * (index) + cardWidth;

                // y = scroll offset/extent / extentBefore

                print("cardOffset: $cardOffset, extentBefore: $extentBefore");

                if (cardOffset > extentBefore + vp) {
                  opacity = 0;
                }

                // Create a horizontal overlap positioning using negative margin
                return
                // Transform.translate(
                //   offset: Offset(
                //     index * (overlap - (step / 6)),
                //     // 0,
                //     0,
                //   ),
                //   child: widget.itemBuilder(context, index),
                // );
                Transform.translate(
                  offset: Offset(index * (overlap - (step / 6)), 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: 1,
                        //  temporarily deprecated
                        // scale: scale,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: cardWidth,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          // remove right margin so cards sit tightly
                          child: widget.itemBuilder(context, index),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
