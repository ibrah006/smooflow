import '../models/printer.dart';

class PrinterState {
  final List<Printer> printers;
  final bool loading;
  final String? error;

  const PrinterState({
    this.printers = const [],
    this.loading = false,
    this.error,
  });

  PrinterState copyWith({
    List<Printer>? printers,
    bool? loading,
    String? error,
  }) {
    return PrinterState(
      printers: printers ?? this.printers,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
