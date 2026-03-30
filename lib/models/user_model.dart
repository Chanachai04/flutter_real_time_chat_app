class UserModel {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  // constructor สำหรับสร้าง object
  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  // factory constructor: ใช้แปลง JSON (Map) -> UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // method: ใช้แปลง UserModel -> JSON (Map)
  // เอาไว้ส่งกลับ API หรือเก็บลง database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // copyWith: เอาไว้ "clone object แล้วแก้บางค่า"
  UserModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // override method จาก Object เพื่อกำหนดรูปแบบ string เวลา print object
  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, fullName: $fullName)';
  }

  // override operator == เพื่อกำหนดว่า object 2 ตัว "เท่ากัน" ยังไง
  @override
  bool operator ==(Object other) {
    // เช็คว่าเป็น object เดียวกันใน memory ไหม
    if (identical(this, other)) return true;

    // เช็คว่าอีกตัวเป็น UserModel และมี id เท่ากัน
    // ถ้า id เท่ากัน = ถือว่าเป็น user คนเดียวกัน
    return other is UserModel && other.id == id;
  }

  // override hashCode (ต้องมีคู่กับ == เสมอ)
  @override
  // ใช้ id เป็นตัวสร้าง hash
  // เพื่อให้ Set / Map ทำงานถูกต้อง
  int get hashCode => id.hashCode;
}
