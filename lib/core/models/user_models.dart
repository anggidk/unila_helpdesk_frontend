enum UserRole { registered, guest, admin }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.entity,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String entity;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _roleFromString(json['role']?.toString() ?? ''),
      entity: json['entity']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': _roleToString(role),
      'entity': entity,
    };
  }
}

UserRole _roleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'guest':
      return UserRole.guest;
    default:
      return UserRole.registered;
  }
}

String _roleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.guest:
      return 'guest';
    case UserRole.registered:
      return 'registered';
  }
}
