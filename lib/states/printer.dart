import 'package:smooflow/data/production_report_details.dart';

import '../models/printer.dart';

class PrinterState {
  final List<Printer> printers;
  final List<Printer> activePrinters;
  final bool loading;
  final String? error;
  final int totalPrintersCount;

  final Map<ReportPeriod, ProductionReportDetails> report;

  const PrinterState({
    this.printers = const [],
    this.activePrinters = const [],
    this.loading = false,
    this.error,
    this.totalPrintersCount = 0,
    this.report = const {}
  });

  PrinterState copyWith({
    List<Printer>? printers,
    List<Printer>? activePrinters,
    bool? loading,
    String? error,
    int? totalPrintersCount,
    Map<ReportPeriod, ProductionReportDetails>? report
  }) {
    return PrinterState(
      printers: printers ?? this.printers,
      activePrinters: activePrinters ?? this.activePrinters,
      loading: loading ?? this.loading,
      error: error,
      totalPrintersCount: totalPrintersCount ?? this.totalPrintersCount,
      report: report?? this.report
    );
  }

  List<Printer> byStatus({required List<PrinterStatus>? statuses}) {
    return statuses==null?
      printers
      : printers.where((printer)=> statuses.contains(printer.status)).toList();
  }

  int countByStatus({required List<PrinterStatus>? statuses}) {
    return byStatus(statuses: statuses).length;
  }
}
