import 'package:flutter_real_time_chat_app/models/message_model.dart';
import 'user_model.dart';

class ConversationModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  UserModel? otherUser;
  MessageModel? lastMessage;
  int unreadCount;

  // constructor สำหรับสร้าง object
  ConversationModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  // factory constructor: ใช้แปลง JSON (Map) -> ConversationModel
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  // method: ใช้แปลง ConversationModel -> JSON (Map)
  // เอาไว้ส่งกลับ API หรือเก็บลง database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  // copyWith: เอาไว้ "clone object แล้วแก้บางค่า"
  ConversationModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? otherUser,
    MessageModel? lastMessage,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  // override method จาก Object เพื่อกำหนดรูปแบบ string เวลา print object
  @override
  String toString() {
    return 'ConversationModel(id: $id, otherUser: ${otherUser?.username}, lastMessage: ${lastMessage?.content})';
  }

  // override operator == เพื่อกำหนดว่า object 2 ตัว "เท่ากัน" ยังไง
  @override
  bool operator ==(Object other) {
    // เช็คว่าเป็น object เดียวกันใน memory ไหม
    if (identical(this, other)) return true;

    // เช็คว่าอีกตัวเป็น ConversationModel และมี id เท่ากัน
    // ถ้า id เท่ากัน = ถือว่าเป็น conversation คนเดียวกัน
    return other is ConversationModel && other.id == id;
  }

  // override hashCode (ต้องมีคู่กับ == เสมอ)
  @override
  // ใช้ id เป็นตัวสร้าง hash
  // เพื่อให้ Set / Map ทำงานถูกต้อง
  int get hashCode => id.hashCode;
}
