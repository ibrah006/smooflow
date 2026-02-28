import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/data/production_report_details.dart';
import 'package:smooflow/core/repositories/printer_repo.dart';
import 'package:smooflow/states/printer.dart';

import '../core/models/printer.dart';

class PrinterNotifier extends StateNotifier<PrinterState> {
  final PrinterRepo _repo;

  PrinterNotifier(this._repo) : super(PrinterState());

  // -------------------------------
  // LOAD ALL PRINTERS
  // -------------------------------
  Future<void> fetchPrinters() async {
    state = state.copyWith(loading: true, error: null);

    // try {
      final result = await _repo.getPrinters();
      await fetchActivePrinters();
      state = state.copyWith(printers: result, loading: false);
    // } catch (e) {
    //   print("error occurred: $e");
    //   state = state.copyWith(loading: false, error: e.toString());
    // }
  }

  // -------------------------------
  // LOAD ACTIVE PRINTERS
  // -------------------------------
  Future<void> fetchActivePrinters() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repo.getActivePrinters();
      state = state.copyWith(activePrinters: result["activePrinters"], totalPrintersCount: result["totalPrintersCount"], loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // -------------------------------
  // CREATE PRINTER
  // -------------------------------
  Future<void> createPrinter({
    required String name,
    String? nickname,
    String? location,
    double? maxWidth,
    double? printSpeed,
  }) async {
    // try {
      final printer = await _repo.createPrinter(
        name: name,
        nickname: nickname,
        location: location,
        maxWidth: maxWidth,
        printSpeed: printSpeed,
      );

      state = state.copyWith(
        printers: [...state.printers, printer],
        totalPrintersCount: state.totalPrintersCount + 1,
        activePrinters: printer.isActive? [...state.activePrinters, printer] : null);
    // } catch (e) {
    //   print("error occurred while creating printer: $e");
    //   state = state.copyWith(error: e.toString());
    // }
  }

  // -------------------------------
  // UPDATE PRINTER (PARTIAL)
  // -------------------------------
  Future<void> updatePrinter(
    String id, {
    String? name,
    String? nickname,
    String? location,
    PrinterStatus? status,
    double? maxWidth,
    double? printSpeed,
  }) async {
    try {
      final updated = await _repo.updatePrinter(
        id,
        name: name,
        nickname: nickname,
        location: location,
        status: status,
        maxWidth: maxWidth,
        printSpeed: printSpeed,
      );

      final list = [...state.printers];
      final index = list.indexWhere((e) => e.id == id);

      if (index != -1) {
        list[index] = updated;
      }

      state = state.copyWith(printers: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // -------------------------------
  // DELETE PRINTER
  // -------------------------------
  Future<void> deletePrinter(String id) async {
    try {
      await _repo.deletePrinter(id);

      state = state.copyWith(
        printers: state.printers.where((e) => e.id != id).toList(),
        totalPrintersCount: state.totalPrintersCount - 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Fetch production report for a given period
  Future<void> fetchReport(
    ReportPeriod period,
  ) async {    
    // try {
    //   state = state.copyWith(loading: true);
    // } catch(e) {}
  
    try {
      final reportResponse = await _repo.getProductionReport(period);

      if (!reportResponse.success) {
        state = state.copyWith(error: "Failed to Production Report", loading: false);
      }
      
      state = state.copyWith(
        report: {...state.report, period: reportResponse.data}
      );
    
    } catch(e) {
      state = state.copyWith(error: e.toString(), loading: false);
      rethrow;
    }
  }

  /// Lazy loading (only reload if empty)
  Future<ProductionReportDetails> ensureReportLoaded(ReportPeriod period) async {
    final report = state.report[period];

    if (report == null) {
      await fetchReport(period);
    }

    return state.report[period]!;
  }

  // Only use this in the task provider file along with TaskNotifier.assignPrinter
  void assignTask({required String printerId, required int taskId}) {
    state.silentSetPrinters = state.printers.map(
      (printer) {
        if (printer.id == printerId) printer.assignJob(jobId: taskId);
        return printer;
      }
    ).toList();
  }

  // Only use this in the task provider file along with TaskNotifier.unassignPrinter
  void unassignTask({required int taskId}) {
    state.copyWith(
      printers: state.printers.map(
        (printer) {
          if (printer.currentJobId == taskId) printer.unassignJob();
          return printer;
        }
      ).toList()
    );
  }
}
