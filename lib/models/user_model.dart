/// User model representing a registered user in the app
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePicUrl;
  final String? phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicUrl,
    this.phone,
  });

  // Convert from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePicUrl: map['profilePicUrl'],
      phone: map['phone'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      if (profilePicUrl != null) 'profilePicUrl': profilePicUrl,
      if (phone != null) 'phone': phone,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePicUrl,
    String? phone,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      phone: phone ?? this.phone,
    );
  }
}
