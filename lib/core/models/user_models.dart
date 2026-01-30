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

  String get roleLabel {
    switch (role) {
      case UserRole.registered:
        return 'Terdaftar';
      case UserRole.guest:
        return 'Guest';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
