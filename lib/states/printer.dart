import '../models/printer.dart';

class PrinterState {
  final List<Printer> printers;
  final List<Printer> activePrinters;
  final bool loading;
  final String? error;

  const PrinterState({
    this.printers = const [],
    this.activePrinters = const [],
    this.loading = false,
    this.error,
  });

  PrinterState copyWith({
    List<Printer>? printers,
    List<Printer>? activePrinters,
    bool? loading,
    String? error,
  }) {
    return PrinterState(
      printers: printers ?? this.printers,
      activePrinters: activePrinters ?? this.activePrinters,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
