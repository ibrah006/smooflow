enum InvitationStatus { pending, accepted, cancelled, expired }

class Invitation {
  final String id;
  // Invitation-to email
  final String email;
  InvitationStatus status;
  final String? role;
  final DateTime? expiresAt;
  final String? invitedBy;
  final String? organizationId;
  final DateTime? createdAt;
  final String organizationName;

  Invitation({
    required this.id,
    required this.email,
    required this.status,
    this.role,
    this.expiresAt,
    this.invitedBy,
    this.organizationId,
    this.createdAt,
    required this.organizationName,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    print("inv json: $json");
    return Invitation(
      id: json['id'],
      email: json['email'],
      status: InvitationStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == json['status'].toString().toLowerCase(),
        orElse: () => InvitationStatus.pending,
      ),
      role: json['role'],
      expiresAt:
          json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'])
              : null,
      invitedBy: json['invitedBy']?['id'],
      organizationId: (json['organization'] as Map)["id"],
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      organizationName: (json["organization"] as Map)["name"],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'status': status.name,
    'role': role,
    'expiresAt': expiresAt?.toIso8601String(),
    'organization': {'name': organizationName, 'id': organizationId},
  };

  // @override
  // List<Object?> get props => [id, email, status, role];
}
