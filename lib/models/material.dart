import 'dart:convert';

import 'package:smooflow/services/login_service.dart';

enum MeasureType {
  running_meter,
  item_quantity,
  liters,
  kilograms,
  square_meter,
}

MeasureType measureTypeFromString(String type) {
  return MeasureType.values.firstWhere(
    (e) => e.name.toLowerCase() == type.toLowerCase(),
    orElse: () => MeasureType.item_quantity,
  );
}

String measureTypeToString(MeasureType type) => type.name;

class MaterialModel {
  late final String id;
  final String name;
  final String? description;
  final MeasureType measureType;
  double _currentStock;
  final double minStockLevel;
  final String organizationId;
  final String createdById;
  late final DateTime createdAt;
  late final DateTime updatedAt;
  // Material barcodes are auto generated upon insert in database
  late final String barcode;

  double get currentStock => _currentStock;
  set currentStock(double newStockValue) => _currentStock = newStockValue;

  MaterialModel({
    required this.id,
    required this.name,
    this.description,
    required this.measureType,
    required double currentStock,
    required this.minStockLevel,
    required this.organizationId,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    required this.barcode,
  }) : _currentStock = currentStock;

  MaterialModel.create({
    required String name,
    required this.description,
    required this.measureType,
    this.minStockLevel = 0,
  }) : _currentStock = 0.0,
       organizationId = LoginService.currentUser!.organizationId,
       name = name.toLowerCase(),
       createdById = LoginService.currentUser!.id;

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      name: json['name'].toString().toLowerCase(),
      description: json['description'],
      measureType: measureTypeFromString(json['measureType']),
      currentStock: double.parse(json['currentStock']),
      minStockLevel: double.parse(json['minStockLevel']),
      organizationId: json['organizationId'],
      createdById: json['createdById'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      barcode: json["barcode"],
    );
  }

  // To ensure toSet gives no duplicates
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialModel &&
          runtimeType == other.runtimeType &&
          id == other.id;
  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'measureType': measureTypeToString(measureType),
      'currentStock': currentStock,
      'minStockLevel': minStockLevel,
      'organizationId': organizationId,
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson({int initialStock = 0}) {
    return {
      'name': name,
      'description': description,
      'measureType': measureTypeToString(measureType),
      'initialStock': initialStock,
      'minStockLevel': minStockLevel,
    };
  }

  static List<MaterialModel> listFromJson(String jsonString) {
    final data = jsonDecode(jsonString) as List;
    return data.map((e) => MaterialModel.fromJson(e)).toList();
  }

  MaterialModel copyWith({
    String? id,
    String? name,
    String? description,
    MeasureType? measureType,
    double? currentStock,
    double? minStockLevel,
    String? organizationId,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? organization,
    Map<String, dynamic>? createdBy,
    List<Map<String, dynamic>>? transactions,
    String? barcode,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      measureType: measureType ?? this.measureType,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      organizationId: organizationId ?? this.organizationId,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      barcode: barcode ?? this.barcode,
    );
  }

  bool get isLowStock => currentStock < minStockLevel;
  bool get isCriticalStock => currentStock <= 0;

  String get unit {
    switch (measureType) {
      case MeasureType.running_meter:
        return "meters";
      case MeasureType.item_quantity:
        return "units";
      case MeasureType.kilograms:
        return "kgs";
      case MeasureType.liters:
        MeasureType.liters.name;
      default:
        return "sqm";
    }
    return "";
  }

  String get unitShort {
    switch (measureType) {
      case MeasureType.running_meter:
        return "m";
      case MeasureType.item_quantity:
        return "u";
      case MeasureType.kilograms:
        return "kgs";
      case MeasureType.liters:
        MeasureType.liters.name;
      default:
        return "sqm";
    }
    return "";
  }
}
