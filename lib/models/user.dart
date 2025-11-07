class User {
  String id;
  String email;
  String name;
  String phone;
  DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool isValid() {
    return email.isNotEmpty &&
        email.contains('@') &&
        name.isNotEmpty &&
        phone.length == 8 &&
        int.tryParse(phone) != null;
  }
}
