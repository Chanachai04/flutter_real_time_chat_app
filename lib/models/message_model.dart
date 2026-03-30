class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? senderUsername;
  String? senderAvatarUrl;

  // constructor สำหรับสร้าง object
  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.senderUsername,
    this.senderAvatarUrl,
  });

  // factory constructor: ใช้แปลง JSON (Map) -> MessageModel
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      senderUsername: json['sender_username'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
    );
  }

  // method: ใช้แปลง MessageModel -> JSON (Map)
  // เอาไว้ส่งกลับ API หรือเก็บลง database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // copyWith: เอาไว้ "clone object แล้วแก้บางค่า"
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderUsername,
    String? senderAvatarUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderUsername: senderUsername ?? this.senderUsername,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }

  // override method จาก Object เพื่อกำหนดรูปแบบ string เวลา print object
  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
  }

  // override operator == เพื่อกำหนดว่า object 2 ตัว "เท่ากัน" ยังไง
  @override
  bool operator ==(Object other) {
    // เช็คว่าเป็น object เดียวกันใน memory ไหม
    if (identical(this, other)) return true;

    // เช็คว่าอีกตัวเป็น MessageModel และมี id เท่ากัน
    // ถ้า id เท่ากัน = ถือว่าเป็น message คนเดียวกัน
    return other is MessageModel && other.id == id;
  }

  // override hashCode (ต้องมีคู่กับ == เสมอ)
  @override
  // ใช้ id เป็นตัวสร้าง hash
  // เพื่อให้ Set / Map ทำงานถูกต้อง
  int get hashCode => id.hashCode;
}
