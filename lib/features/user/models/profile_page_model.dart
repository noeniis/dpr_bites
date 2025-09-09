class ProfileModel {
  final String name;
  final String username;
  final String phone;
  final String email;
  final String photo;

  ProfileModel({
    required this.name,
    required this.username,
    required this.phone,
    required this.email,
    required this.photo,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: (json['nama_lengkap'] ?? json['nama'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      phone: (json['no_hp'] ?? json['no_telp'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      photo: (json['photo_path'] ?? json['photo'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_lengkap': name,
      'username': username,
      'no_hp': phone,
      'email': email,
      'photo_path': photo,
    };
  }

  ProfileModel copyWith({
    String? name,
    String? username,
    String? phone,
    String? email,
    String? photo,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photo: photo ?? this.photo,
    );
  }
}
