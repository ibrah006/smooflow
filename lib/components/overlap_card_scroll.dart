import 'package:flutter/material.dart';

class OverlapCardScroll extends StatefulWidget {
  const OverlapCardScroll({super.key});

  @override
  State<OverlapCardScroll> createState() => _OverlapCardScrollState();
}

class _OverlapCardScrollState extends State<OverlapCardScroll> {
  final PageController _pageController = PageController(viewportFraction: 0.6);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = List.generate(
      8,
      (index) => PrinterCard(
        printerName: "Printer ${index + 1}",
        role: "Production Head",
        incharge: "Ali Yusuf",
      ),
    );

    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: cards.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 0.0;
              if (_pageController.position.haveDimensions) {
                value = index - (_pageController.page ?? 0);
              }

              // shrink cards to the right of selected
              double scale =
                  (index == _currentPage + 1) ? 0.9 : (value > 1 ? 0.6 : 1.0);

              // shift left cards slightly
              double offsetX = (value < 0) ? value * 50 : 0;

              // fade out far right cards
              double opacity = (value > 1) ? 0.0 : 1.0;

              return Transform.translate(
                offset: Offset(offsetX, 0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Opacity(opacity: opacity, child: child),
                ),
              );
            },
            child: cards[index],
          );
        },
      ),
    );
  }
}

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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            printerName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.print, size: 60, color: Colors.black87),
          const SizedBox(height: 12),
          Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(incharge, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
