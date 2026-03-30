import 'package:flutter_real_time_chat_app/models/conversation_model.dart';
import 'package:flutter_real_time_chat_app/models/message_model.dart';
import 'package:flutter_real_time_chat_app/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  // สร้าง instance ของ SupabaseClient จาก global instance
  final SupabaseClient _supabase = Supabase.instance.client;

  // getter: เอา id ของ user ที่ login อยู่ตอนนี้
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ค้นหาผู้ใช้จาก username โดยใช้เงื่อนไขแบบ LIKE (case-insensitive)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final currentUser = currentUserId;

      // ตรวจสอบว่าผู้ใช้ login แล้วหรือไม่
      if (currentUser == null) throw Exception('User not logged in');

      final data = await _supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .neq('id', currentUser)
          .limit(20);

      // แปลงข้อมูล JSON เป็น UserModel
      return (data as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('failed to search users: $e');
    }
  }

  // ดึงผู้ใช้ทั้งหมด ยกเว้น user ปัจจุบัน
  Future<List<UserModel>> getAllUsers() async {
    try {
      final currentUser = currentUserId;

      // ตรวจสอบว่าผู้ใช้ login แล้วหรือไม่
      if (currentUser == null) throw Exception('User not logged in');

      final data = await _supabase
          .from('profiles')
          .select()
          .neq('id', currentUser) // ไม่รวมตัวเอง
          .order('username');

      // แปลงข้อมูล JSON เป็น UserModel
      return (data as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('failed to get all users: $e');
    }
  }

  // ตรวจสอบว่ามี conversation อยู่แล้วหรือไม่ หากไม่มีจะสร้างใหม่
  Future<String> getOrCreateConversation(String otherUserId) async {
    try {
      final currentUser = currentUserId;

      // ตรวจสอบว่าผู้ใช้ login แล้วหรือไม่
      if (currentUser == null) throw Exception('User not logged in');

      // ดึง conversation ทั้งหมดที่ user ปัจจุบันมีส่วนร่วม
      final existingConversation = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', currentUser);

      // conv -> conversation
      // ตรวจสอบทีละ conversation ว่ามีอีก user อยู่ด้วยหรือไม่
      for (var conv in existingConversation) {
        final conversationId = conv['conversation_id'] as String;
        final otherParticipants = await _supabase
            .from('conversation_participants')
            .select()
            .eq('conversation_id', conversationId)
            .eq('user_id', currentUser);

        // หากพบว่ามี conversation อยู่แล้ว ให้ใช้ id เดิม
        if (otherParticipants.isNotEmpty) {
          return conversationId;
        }
      }

      // หากไม่มี conversation ให้สร้างใหม่
      final conversationData = await _supabase
          .from('conversations')
          .insert({})
          .select()
          .single();

      final conversationId = conversationData['id'];

      // เพิ่มผู้เข้าร่วมทั้งสองคน
      await _supabase.from('conversation_participants').insert([
        {'conversation_id': conversationId, 'user_id': currentUser},
        {'conversation_id': conversationId, 'user_id': otherUserId},
      ]);

      return conversationId;
    } catch (e) {
      throw Exception('failed to get or create conversation: $e');
    }
  }

  // ดึงรายการ conversation ทั้งหมดของ user
  Future<List<ConversationModel>> getConversations() async {
    try {
      final currentUser = currentUserId;

      // ตรวจสอบว่าผู้ใช้ login แล้วหรือไม่
      if (currentUser == null) throw Exception('User not logged in');

      // ดึง conversation id ทั้งหมดของ user
      final participantData = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', currentUser);

      List<ConversationModel> conversations = [];

      // loop เพื่อดึงข้อมูลแต่ละ conversation
      for (var participant in participantData) {
        final conversationId = participant['conversation_id'];

        // ดึงข้อมูล conversation
        final conversationData = await _supabase
            .from('conversations')
            .select()
            .eq('id', conversationId)
            .single();

        ConversationModel conversation = ConversationModel.fromJson(
          conversationData,
        );

        // ดึงข้อมูล user อีกฝั่งของ conversation
        final otherUserData = await _supabase
            .from('conversation_participants')
            .select('user_id, profiles(*)')
            .eq('conversation_id', conversationId)
            .neq('user_id', currentUser)
            .single();

        conversation.otherUser = UserModel.fromJson(otherUserData['profiles']);

        // ดึง message ล่าสุด
        final lastMessageData = await _supabase
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1);

        if (lastMessageData.isNotEmpty) {
          conversation.lastMessage = MessageModel.fromJson(
            lastMessageData.first,
          );
        }

        // นับจำนวน unread message
        final unreadData = await _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .eq('is_read', false)
            .neq('sender_id', currentUser)
            .count(CountOption.exact);

        conversation.unreadCount = unreadData.count;

        conversations.add(conversation);
      }
      // เรียงตาม updatedAt ล่าสุด
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return conversations;
    } catch (e) {
      throw Exception('failed to get conversations: $e');
    }
  }

  // ดึง messages ทั้งหมดใน conversation
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final data = await _supabase
          .from('messages')
          .select('*, profiles:sender_id(username, avatar_url)')
          // join ตาราง profiles โดยใช้ sender_id
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (data as List).map((json) {
        final message = MessageModel.fromJson(json);
        // แนบข้อมูล sender เพิ่มเข้าไปใน model
        if (json['profiles'] != null) {
          message.senderUsername = json['profiles']['username'];
          message.senderAvatarUrl = json['profiles']['avatar_url'];
        }
        return message;
      }).toList();
    } catch (e) {
      throw Exception('failed to get messages: $e');
    }
  }

  // ส่งข้อความใหม่ไปยัง conversation
  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    try {
      final currentUser = currentUserId;

      // ตรวจสอบว่าผู้ใช้ login แล้วหรือไม่
      if (currentUser == null) throw Exception('User not logged in');

      final messageData = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': currentUser,
            'content': content,
          })
          .select()
          .single();

      return MessageModel.fromJson(messageData);
    } catch (e) {
      throw Exception('failed to send message: $e');
    }
  }

  // อัปเดตสถานะข้อความเป็นอ่านแล้ว
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final currentUser = currentUserId;

      // ตรวจสอบว่าผู้ใช้ login แล้วหรือไม่
      if (currentUser == null) throw Exception('User not logged in');

      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUser)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('failed to mark messages as read: $e');
    }
  }

  // รับ message แบบ realtime โดยใช้ stream
  Stream<MessageModel> istenToMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.map((json) => MessageModel.fromJson(json)).toList())
        // แปลง List<MessageModel> เป็น MessageModel ทีละตัว
        .expand((messages) => messages);
  }

  // รับ conversation แบบ realtime
  Stream<List<Map<String, dynamic>>> listenToConversations() {
    final currentUser = currentUserId;

    // หากยังไม่ได้ login ให้ return stream ว่าง
    if (currentUser == null) {
      const Stream.empty();
    }

    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        // ส่งข้อมูลออกมาเป็น List<Map<String, dynamic>>
        .map((data) => data.map((json) => json).toList());
  }
}
