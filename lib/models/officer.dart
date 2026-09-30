class Officer {
  final String name;
  final String id;
  final String role;
  final String district;
  final String email;
  final String password;

  const Officer({
    required this.name,
    required this.id,
    required this.role,
    required this.district,
    required this.email,
    required this.password,
  });

  bool get isAdmin => role == 'District Administrator';

  Officer copyWith({
    String? name,
    String? id,
    String? role,
    String? district,
    String? email,
    String? password,
  }) {
    return Officer(
      name: name ?? this.name,
      id: id ?? this.id,
      role: role ?? this.role,
      district: district ?? this.district,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}
