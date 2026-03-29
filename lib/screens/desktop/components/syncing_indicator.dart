import 'package:flutter/material.dart';

class SyncingIndicator extends StatefulWidget {
  const SyncingIndicator();

  @override
  State<SyncingIndicator> createState() => _SyncingIndicatorState();
}

class _SyncingIndicatorState extends State<SyncingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Syncing quotation to server…',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          final opacity = 0.35 + 0.65 * _pulse.value;
          return Opacity(
            opacity: opacity,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      Color.lerp(
                        const Color(0xFF90CAF9),
                        const Color(0xFF1976D2),
                        _pulse.value,
                      )!,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 16,
                color: Color.lerp(
                  const Color(0xFF90CAF9),
                  const Color(0xFF1565C0),
                  _pulse.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
