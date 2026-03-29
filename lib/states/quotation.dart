import 'package:smooflow/core/models/quotation.dart';

class QuotationState {
  final List<Quotation> quotations;

  QuotationState({required this.quotations});

  QuotationState copyWith({List<Quotation>? quotations, Quotation? quotation}) {
    quotations = quotations ?? this.quotations;

    if (quotation != null) {
      final quotationIndex = quotations.indexWhere(
        (q) => q.number == quotation.number,
      );

      if (quotationIndex != -1) quotations.removeAt(quotationIndex);

      quotations.insert(0, quotation);
    }

    return QuotationState(quotations: quotations);
  }
}
