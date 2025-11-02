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
  final double currentStock;
  final double minStockLevel;
  final String organizationId;
  final String createdById;
  late final DateTime createdAt;
  late final DateTime updatedAt;

  MaterialModel({
    required this.id,
    required this.name,
    this.description,
    required this.measureType,
    required this.currentStock,
    required this.minStockLevel,
    required this.organizationId,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  MaterialModel.create({
    required String name,
    required this.description,
    required this.measureType,
    this.minStockLevel = 0,
  }) : currentStock = 0.0,
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
    );
  }

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
    );
  }

  bool get isLowStock => currentStock < minStockLevel;
  bool get isCriticalStock => currentStock <= 0;
}
