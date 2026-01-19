

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/notifiers/printer_notifier.dart';
import 'package:smooflow/core/repositories/printer_repo.dart';
import 'package:smooflow/states/printer.dart';

final printerRepoProvider = Provider<PrinterRepo>((ref) {
  return PrinterRepo();
});

final printerNotifierProvider =
    StateNotifierProvider<PrinterNotifier, PrinterState>((ref) {
      final repo = ref.read(printerRepoProvider);
      return PrinterNotifier(repo);
    });
