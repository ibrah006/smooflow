import 'dart:convert';

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
  final String id;
  final String name;
  final String? description;
  final MeasureType measureType;
  final double currentStock;
  final double minStockLevel;
  final String organizationId;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional relations (you can fill these when fetching nested data)
  final Map<String, dynamic>? organization;
  final Map<String, dynamic>? createdBy;
  final List<Map<String, dynamic>>? transactions;

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
    this.organization,
    this.createdBy,
    this.transactions,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      measureType: measureTypeFromString(json['measureType']),
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (json['minStockLevel'] as num?)?.toDouble() ?? 0.0,
      organizationId: json['organizationId'],
      createdById: json['createdById'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      organization: json['organization'],
      createdBy: json['createdBy'],
      transactions:
          (json['transactions'] as List?)
              ?.map((t) => Map<String, dynamic>.from(t))
              .toList(),
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
      'organization': organization,
      'createdBy': createdBy,
      'transactions': transactions,
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
      organization: organization ?? this.organization,
      createdBy: createdBy ?? this.createdBy,
      transactions: transactions ?? this.transactions,
    );
  }
}
