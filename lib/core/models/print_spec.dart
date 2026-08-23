// print_spec.dart
import 'dart:math';

class PrintSpec {
  late final int _id;

  int get id {
    try {
      return _id;
    } catch (e) {
      return _tempId!;
    }
  }

  String? ref;
  String? size;
  int? quantity;

  // OPEN ITEM: frontend-only linkage to a locally-uploaded spec sheet this
  // size was extracted from. Not sent to the backend yet (excluded from
  // toJson/toCreateJson) — wire this up once the extraction endpoint exists.
  int? sourceSheetId;

  int? _tempId;

  double get width {
    return size != null ? double.tryParse(size!.split('×').first) ?? 0 : 0;
  }

  double get height {
    return size != null && unit != null
        ? double.tryParse(size!.split('×')[1].split(unit!).first.trim()) ?? 0
        : 0;
  }

  String? get unit {
    try {
      return size != null ? size!.split('×')[1].split(' ')[1] : null;
    } catch (e) {
      return null;
    }
  }

  PrintSpec({
    required int id,
    this.ref,
    this.size,
    this.quantity,
    this.sourceSheetId,
  }) : _id = id;

  PrintSpec.create({this.ref, this.size, int quantity = 1, this.sourceSheetId})
    : _tempId = Random().nextInt(2000000) * -1,
      this.quantity = quantity;

  factory PrintSpec.fromJson(Map<String, dynamic> json) {
    return PrintSpec(
      id: json['id'] as int,
      ref: json['ref'] as String?,
      size: json['size'] as String?,
      quantity: json['quantity'] as int?,
    );
  }

  void initializeId(int newId) {
    _id = newId;
  }

  Map<String, dynamic> toJson() {
    return {'ref': ref, 'size': size, 'quantity': quantity, 'id': id};
  }

  Map<String, dynamic> toCreateJson() {
    return {...toJson(), 'tempLocalId': id};
  }

  PrintSpec._copyWithTempId(
    this._tempId,
    this.ref,
    this.size,
    this.quantity,
    this.sourceSheetId,
  );

  PrintSpec copyWith({
    int? id,
    String? ref,
    String? size,
    int? quantity,
    int? sourceSheetId,
    bool clearSourceSheetId = false,
  }) {
    // NOTE: previously the draft (id < 0) branch passed ref/size/quantity
    // through raw instead of falling back to `this.*`, so editing a single
    // field on a draft silently wiped the others. Fixed to fall back like
    // the persisted-item branch already did.
    return (id ?? this.id) < 0
        ? PrintSpec._copyWithTempId(
          id ?? this.id,
          ref ?? this.ref,
          size ?? this.size,
          quantity ?? this.quantity,
          clearSourceSheetId ? null : (sourceSheetId ?? this.sourceSheetId),
        )
        : PrintSpec(
          id: id ?? this.id,
          ref: ref ?? this.ref,
          size: size ?? this.size,
          quantity: quantity ?? this.quantity,
          sourceSheetId:
              clearSourceSheetId ? null : (sourceSheetId ?? this.sourceSheetId),
        );
  }
}
