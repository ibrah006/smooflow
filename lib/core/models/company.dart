import 'dart:math';

import 'package:flutter/material.dart' show Color, Colors;
import 'package:smooflow/core/services/login_service.dart';
import 'package:uuid/uuid.dart';

import 'user.dart';
import 'project.dart';

class Company {
  final String id;
  // Company name
  final String name;
  final String description;
  final bool isActive;
  late final DateTime createdAt;
  final String createdByUserId;
  final List<String> projects;

  final bool _isSample; // private flag for sample data

  String? email;
  String? industry;
  String? phone;
  String? contactName;
  Color? _color;

  Color get color {
    return _color?? Colors.grey;
  }

  set color(Color? value) {
    _color = value;
  }

  // Sample data check
  bool get isSample => _isSample;

  String get initials {
    final splitted = name.split(" ");

    String result = "";

    while(splitted.isNotEmpty && result.length < 4) {
      result += splitted[0][0].toUpperCase();
      splitted.removeAt(0);
    }

    return result;
  }

  Company({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.createdByUserId,
    required this.projects,
    required this.email,
    required this.industry,
    required this.phone,
    required this.contactName,
    required Color? color
  }) : _color = color, _isSample = false;

  Company.create({
    required this.name,
    required this.description,
    this.email,
    this.industry,
    this.phone,
    this.contactName,
    Color? color})
    : _color = color??
    // Get random color
     [Color(0xFF2563EB),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B)][Random().nextInt(4)],
      id = Uuid().v1(),
      isActive = true,
      createdByUserId = LoginService.currentUser!.id,
      projects = [],
      _isSample = false;

  // Sample constructor
  Company.sample()
    : id = 'sample-company-id',
      name = 'Sample Company',
      description = 'This is a sample company for demo/testing purposes.',
      isActive = true,
      createdAt = DateTime.now(),
      createdByUserId = "SAMPLE",
      projects = [],
      _isSample = true;

  static String getIdFromJson(Map<String, dynamic> companyJson) {
    return companyJson["id"];
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      createdByUserId: User.getIdFromJson(json['createdBy']),
      projects:
          ((json['projects'] ?? []) as List<dynamic>)
              .map((projectJson) => Project.getIdFromJson(projectJson))
              .toList(),
      email: json['emial'],
      phone: json['phone'],
      industry: json['industry'],
      contactName: json["contactName"],
      color: (json["color"])
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdBy': createdByUserId,
      'projects': projects,
      'email': email,
      'phone': phone,
      'industry': industry,
      'contactName': contactName,
      'color': _colorToHex(color)
    };
  }
}

String? _colorToHex(Color? color) {
  if (color == null) return null; 
  return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
