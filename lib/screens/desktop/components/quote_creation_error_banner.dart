import 'package:flutter/material.dart';

class QuoteCreationErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const QuoteCreationErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFFFCDD2), width: 1),
          left: BorderSide(color: const Color(0xFFE53935), width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFE53935),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quotation not saved to server',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'This quotation exists locally but hasn\'t been created in the system yet — likely due to a connection issue. Your edits here are safe. Retry when ready.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB71C1C),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Retry Create',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
