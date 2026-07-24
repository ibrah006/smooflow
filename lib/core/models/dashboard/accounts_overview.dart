// lib/core/models/dashboard/accounts_overview.dart

class AccountsOverview {
  final AccountsInvoices invoices;
  final AccountsPayments payments;
  final AccountsQuotations quotations;
  final List<ProjectFinancial> projectFinancials;

  AccountsOverview({
    required this.invoices,
    required this.payments,
    required this.quotations,
    required this.projectFinancials,
  });

  factory AccountsOverview.fromJson(Map<String, dynamic> json) {
    return AccountsOverview(
      invoices: AccountsInvoices.fromJson(
        json['invoices'] as Map<String, dynamic>,
      ),
      payments: AccountsPayments.fromJson(
        json['payments'] as Map<String, dynamic>,
      ),
      quotations: AccountsQuotations.fromJson(
        json['quotations'] as Map<String, dynamic>,
      ),
      projectFinancials:
          ((json['projectFinancials'] as List?) ?? [])
              .map((p) => ProjectFinancial.fromJson(p as Map<String, dynamic>))
              .toList(),
    );
  }
}

class AccountsInvoices {
  final List<InvoiceStatusCount> statusCounts;
  final List<OverdueInvoice> overdue;
  final List<RecentInvoice> recentlyIssued;

  AccountsInvoices({
    required this.statusCounts,
    required this.overdue,
    required this.recentlyIssued,
  });

  factory AccountsInvoices.fromJson(Map<String, dynamic> json) {
    return AccountsInvoices(
      statusCounts:
          ((json['statusCounts'] as List?) ?? [])
              .map(
                (s) => InvoiceStatusCount.fromJson(s as Map<String, dynamic>),
              )
              .toList(),
      overdue:
          ((json['overdue'] as List?) ?? [])
              .map((o) => OverdueInvoice.fromJson(o as Map<String, dynamic>))
              .toList(),
      recentlyIssued:
          ((json['recentlyIssued'] as List?) ?? [])
              .map((r) => RecentInvoice.fromJson(r as Map<String, dynamic>))
              .toList(),
    );
  }

  double get totalAmountDue =>
      overdue.fold(0, (sum, inv) => sum + inv.amountDue);
  int get draftCount =>
      statusCounts
          .firstWhere(
            (s) => s.status == 'draft',
            orElse:
                () => InvoiceStatusCount(
                  status: 'draft',
                  count: 0,
                  totalAmount: 0,
                ),
          )
          .count;
  int get paidCount =>
      statusCounts
          .firstWhere(
            (s) => s.status == 'paid',
            orElse:
                () => InvoiceStatusCount(
                  status: 'paid',
                  count: 0,
                  totalAmount: 0,
                ),
          )
          .count;
}

class InvoiceStatusCount {
  final String status;
  final int count;
  final double totalAmount;

  InvoiceStatusCount({
    required this.status,
    required this.count,
    required this.totalAmount,
  });

  factory InvoiceStatusCount.fromJson(Map<String, dynamic> json) {
    return InvoiceStatusCount(
      status: json['status'] as String,
      count: json['count'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  String get displayStatus {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'paid':
        return 'Paid';
      case 'partially_paid':
        return 'Partially Paid';
      case 'overdue':
        return 'Overdue';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class OverdueInvoice {
  final String id;
  final String invoiceNumber;
  final String clientName;
  final double amountDue;
  final int daysOverdue;

  OverdueInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.amountDue,
    required this.daysOverdue,
  });

  factory OverdueInvoice.fromJson(Map<String, dynamic> json) {
    return OverdueInvoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      clientName: json['clientName'] as String,
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
      daysOverdue: json['daysOverdue'] as int? ?? 0,
    );
  }
}

class RecentInvoice {
  final String id;
  final String invoiceNumber;
  final String clientName;
  final double totalAmount;
  final DateTime issueDate;

  RecentInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.totalAmount,
    required this.issueDate,
  });

  factory RecentInvoice.fromJson(Map<String, dynamic> json) {
    return RecentInvoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      clientName: json['clientName'] as String,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      issueDate: DateTime.parse(json['issueDate'] as String),
    );
  }
}

class AccountsPayments {
  final double thisMonthTotal;
  final List<PaymentByMethod> byMethod;

  AccountsPayments({required this.thisMonthTotal, required this.byMethod});

  factory AccountsPayments.fromJson(Map<String, dynamic> json) {
    return AccountsPayments(
      thisMonthTotal: (json['thisMonthTotal'] as num?)?.toDouble() ?? 0,
      byMethod:
          ((json['byMethod'] as List?) ?? [])
              .map((p) => PaymentByMethod.fromJson(p as Map<String, dynamic>))
              .toList(),
    );
  }
}

class PaymentByMethod {
  final String method;
  final double total;

  PaymentByMethod({required this.method, required this.total});

  factory PaymentByMethod.fromJson(Map<String, dynamic> json) {
    return PaymentByMethod(
      method: json['method'] as String,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  String get displayMethod {
    switch (method) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'card':
        return 'Card';
      case 'cash':
        return 'Cash';
      case 'cheque':
        return 'Cheque';
      case 'other':
        return 'Other';
      default:
        return method;
    }
  }
}

class AccountsQuotations {
  final List<PendingQuotation> pendingResponse;
  final List<AcceptedQuotation> recentlyAccepted;

  AccountsQuotations({
    required this.pendingResponse,
    required this.recentlyAccepted,
  });

  factory AccountsQuotations.fromJson(Map<String, dynamic> json) {
    return AccountsQuotations(
      pendingResponse:
          ((json['pendingResponse'] as List?) ?? [])
              .map((p) => PendingQuotation.fromJson(p as Map<String, dynamic>))
              .toList(),
      recentlyAccepted:
          ((json['recentlyAccepted'] as List?) ?? [])
              .map((a) => AcceptedQuotation.fromJson(a as Map<String, dynamic>))
              .toList(),
    );
  }

  int get totalPendingCount => pendingResponse.length;
}

class PendingQuotation {
  final String id;
  final String number;
  final String clientName;
  final int daysSinceSent;

  PendingQuotation({
    required this.id,
    required this.number,
    required this.clientName,
    required this.daysSinceSent,
  });

  factory PendingQuotation.fromJson(Map<String, dynamic> json) {
    return PendingQuotation(
      id: json['id'] as String,
      number: json['number'] as String,
      clientName: json['clientName'] as String,
      daysSinceSent: json['daysSinceSent'] as int? ?? 0,
    );
  }

  bool get isStale => daysSinceSent > 7;
}

class AcceptedQuotation {
  final String id;
  final String number;
  final String clientName;
  final double total;

  AcceptedQuotation({
    required this.id,
    required this.number,
    required this.clientName,
    required this.total,
  });

  factory AcceptedQuotation.fromJson(Map<String, dynamic> json) {
    return AcceptedQuotation(
      id: json['id'] as String,
      number: json['number'] as String,
      clientName: json['clientName'] as String,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProjectFinancial {
  final String projectId;
  final String projectName;
  final double quotedTotal;
  final double invoicedTotal;
  final double paidTotal;

  ProjectFinancial({
    required this.projectId,
    required this.projectName,
    required this.quotedTotal,
    required this.invoicedTotal,
    required this.paidTotal,
  });

  factory ProjectFinancial.fromJson(Map<String, dynamic> json) {
    return ProjectFinancial(
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      quotedTotal: (json['quotedTotal'] as num?)?.toDouble() ?? 0,
      invoicedTotal: (json['invoicedTotal'] as num?)?.toDouble() ?? 0,
      paidTotal: (json['paidTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  double get pendingDue => invoicedTotal - paidTotal;
  double get quotedButNotInvoiced => quotedTotal - invoicedTotal;
  double get collectionRate =>
      invoicedTotal > 0 ? (paidTotal / invoicedTotal) * 100 : 0;
}
