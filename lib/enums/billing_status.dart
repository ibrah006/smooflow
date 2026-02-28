enum BillingStatus {
  pending, quoteGiven, invoiced, cancelled, foc;

  String get displayName {
    switch(this) {
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
}