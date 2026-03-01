// ─────────────────────────────────────────────────────────────────────────────
// lib/database/app_database.dart
// Drift local database — Invoices, LineItems, Payments
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── ENUMS ───────────────────────────────────────────────────────────────────

enum InvoiceStatus { draft, sent, paid, partiallyPaid, overdue, cancelled }

enum PaymentMethod { bankTransfer, card, cash, cheque, other }

// ─── TABLES ──────────────────────────────────────────────────────────────────

class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNumber => text()();
  TextColumn get clientId => text()();
  TextColumn get clientName => text()();
  TextColumn get clientEmail => text().nullable()();
  TextColumn get clientAddress => text().nullable()();
  TextColumn get clientTrn => text().nullable()(); // Tax Registration Number
  TextColumn get status => textEnum<InvoiceStatus>()();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get taxRate => real().withDefault(const Constant(5))(); // VAT 5% default UAE
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get amountPaid => real().withDefault(const Constant(0))();
  RealColumn get amountDue => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get terms => text().nullable()();
  TextColumn get organizationId => text()();
  TextColumn get createdById => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class InvoiceLineItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get description => text()();
  TextColumn get unit => text().nullable()(); // e.g. hrs, pcs, etc.
  RealColumn get quantity => real().withDefault(const Constant(1))();
  RealColumn get unitPrice => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get receiptNumber => text()();
  RealColumn get amount => real()();
  TextColumn get method => textEnum<PaymentMethod>()();
  TextColumn get reference => text().nullable()(); // bank ref / cheque number
  TextColumn get notes => text().nullable()();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── DATABASE ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Invoices, InvoiceLineItems, Payments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {},
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'smooflow_accounts.db'));
    return NativeDatabase.createInBackground(file);
  });
}