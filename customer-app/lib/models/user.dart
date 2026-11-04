/// User model matching backend serializer.
class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.isVerified = false,
  });

  final int id;
  final String email;
  final String role; // 'CUSTOMER' | 'MERCHANT' | 'DELIVERY_AGENT' | 'ADMIN'
  final String firstName;
  final String lastName;
  final String phone;
  final bool isVerified;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? email : full;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'CUSTOMER',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        isVerified: json['is_verified'] ?? false,
      );
}