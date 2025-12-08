import '../models/printer.dart';

class PrinterState {
  final List<Printer> printers;
  final List<Printer> activePrinters;
  final bool loading;
  final String? error;
  final int totalPrintersCount;

  const PrinterState({
    this.printers = const [],
    this.activePrinters = const [],
    this.loading = false,
    this.error,
    this.totalPrintersCount = 0
  });

  PrinterState copyWith({
    List<Printer>? printers,
    List<Printer>? activePrinters,
    bool? loading,
    String? error,
    int? totalPrintersCount,
  }) {
    return PrinterState(
      printers: printers ?? this.printers,
      activePrinters: activePrinters ?? this.activePrinters,
      loading: loading ?? this.loading,
      error: error,
      totalPrintersCount: totalPrintersCount ?? this.totalPrintersCount
    );
  }
}
