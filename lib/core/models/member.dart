// Minimal version of USER class for simplicity, but not used for current user
import 'dart:math';

import 'package:flutter/widgets.dart';

class Member {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final List<int> activeTasks;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.activeTasks
  });

  String get initials {
    final n = name.split(" ");
    return n.length > 1? "${n[0]} ${n[1]}" : name[0];
  }

  String get nameShort {
    final n = name.split(" ");
    return n.length > 1? "${n[0]} ${n[1][0]}." : name;
  }

  // Get random color for now
  Color get color {
    return [Color(0xFF2563EB),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B)][Random().nextInt(4)];
  }

  // Factory constructor for creating a User from JSON
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      // TODO: implement this in backend
      activeTasks: []
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
