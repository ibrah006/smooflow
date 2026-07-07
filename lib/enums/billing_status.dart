import 'package:flutter/material.dart';

enum BillingStatus {
  pending,
  quoteGiven,
  invoiced,
  cancelled,
  foc;

  String get displayName {
    switch (this) {
      case BillingStatus.pending:
        return "Pending";
      case BillingStatus.quoteGiven:
        return "Quote Given";
      case BillingStatus.invoiced:
        return "Invoiced";
      case BillingStatus.cancelled:
        return "Cancelled";
      case BillingStatus.foc:
        return "FOC";
    }
  }

  Color get color {
    switch (this) {
      case BillingStatus.pending:
        return const Color(0xFFFDE68A); // Amber
      case BillingStatus.quoteGiven:
        return const Color(0xFFBFDBFE); // Blue
      case BillingStatus.invoiced:
        return const Color(0xFF86EFAC); // Green
      case BillingStatus.cancelled:
        return const Color(0xFFFDA4AF); // Rose
      case BillingStatus.foc:
        return const Color(0xFFC4B5FD); // Purple
    }
  }

  Color get textColor {
    // Use a dark, rich version of the background hue for text
    // This makes the text feel "integrated" rather than just slapped on top
    switch (this) {
      case BillingStatus.pending:
        return const Color(0xFF92400E);
      case BillingStatus.quoteGiven:
        return const Color(0xFF1E40AF);
      case BillingStatus.invoiced:
        return const Color(0xFF065F46);
      case BillingStatus.cancelled:
        return const Color(0xFF9F1239);
      case BillingStatus.foc:
        return const Color(0xFF5B21B6);
    }
  }
}
