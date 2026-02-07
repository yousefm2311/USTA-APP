class CustomerProfile {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? raw;

  CustomerProfile({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.raw,
  });

  factory CustomerProfile.fromMap(Map<String, dynamic> map) {
    final id = (map['_id'] ?? map['id'] ?? '').toString();
    return CustomerProfile(
      id: id,
      name: map['name']?.toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        if (raw != null) ...raw!,
      };
}
