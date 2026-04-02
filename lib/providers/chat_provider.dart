import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_real_time_chat_app/models/conversation_model.dart';
import 'package:flutter_real_time_chat_app/models/message_model.dart';
import 'package:flutter_real_time_chat_app/models/user_model.dart';
import 'package:flutter_real_time_chat_app/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  // service สำหรับจัดการ chat (fetch conversations, send message, etc.)
  final ChatService _chatService = ChatService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  // subscription สำหรับ realtime (ต้อง cancel เอง)
  StreamSubscription? _messageSubscription;
  StreamSubscription? _conversationSubscription;

  // getters ให้ UI เข้าถึง state
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // โหลดรายการ conversation ทั้งหมด
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    // notifyListeners();
    try {
      // ดึงข้อมูลจาก service
      _conversations = await _chatService.getConversations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ค้นหา user
  Future<void> searchUsers(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // ถ้า query ว่าง ให้ โหลด user ทั้งหมด
      if (query.isEmpty) {
        _users = await _chatService.getAllUsers();
      } else {
        // ถ้ามี keyword ให้ search ตาม keyword นั้น
        _users = await _chatService.searchUsers(query);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // โหลด user ทั้งหมด (ใช้ในหน้าเลือกคนแชท)
  Future<void> loadAllUsers() async {
    _isLoading = true;
    _error = null;
    // notifyListeners();
    try {
      // ดึงข้อมูลจาก service
      _users = await _chatService.getAllUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // หา conversation หรือสร้างใหม่
  Future<String?> getOrCreateConversation(String otherUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // ดึงข้อมูลจาก service
      final conversationId = await _chatService.getOrCreateConversation(
        otherUserId,
      );
      _isLoading = false;
      notifyListeners();
      return conversationId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // โหลด message ของ conversation หนึ่ง
  Future<void> loadMessages(String conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // โหลด message ทั้งหมดของ conversation นั้นจาก service
      _messages = await _chatService.getMessages(conversationId);
      // mark ว่า message ถูกอ่านแล้ว
      await _chatService.markMessagesAsRead(conversationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ส่ง message
  Future<bool> sendMessage(String conversationId, String content) async {
    try {
      final message = await _chatService.sendMessage(conversationId, content);
      // เพิ่ม message เข้า state ทันที (optimistic update)
      _messages.add(message);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // subscribe realtime message ของ conversation
  void listenToMessages(String conversationId) {
    // cancel subscription เก่าก่อน (กัน memory leak / duplicate stream)
    _messageSubscription?.cancel();
    _messageSubscription = _chatService
        .listenToMessages(conversationId)
        .listen(
          (message) {
            // เช็คว่า message นี้มีอยู่ใน list แล้วหรือยัง
            final existingIndex = _messages.indexWhere(
              (m) => m.id == message.id,
            );
            if (existingIndex == -1) {
              // ถ้ายังไม่มีให้ เพิ่มใหม่
              _messages.add(message);
              notifyListeners();
              // ถ้า message ไม่ใช่ของเราให้ mark ว่าอ่านแล้ว
              if (message.senderId != _chatService.currentUserId) {
                _chatService.markMessagesAsRead(conversationId);
              }
            } else {
              // ถ้ามีแล้วให้ update message (เช่น read status เปลี่ยน)
              _messages[existingIndex] = message;
              notifyListeners();
            }
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  // หยุดฟัง realtime message
  void stopListeningToMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
  }

  // subscribe realtime conversation
  void listenToConversations() {
    _conversationSubscription?.cancel();
    _conversationSubscription = _chatService.listenToConversations().listen(
      (conversation) {
        // เมื่อมี event → reload conversation ใหม่ทั้งหมด
        loadConversations();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // หยุดฟัง conversation realtime
  void stopListeningToConversations() {
    _conversationSubscription?.cancel();
    _conversationSubscription = null;
  }

  // ล้าง message (เช่น ตอนเปลี่ยนห้องแชท)
  void clearMessage() {
    _messages.clear();
    notifyListeners();
  }

  // ล้าง error (หลัง UI แสดงแล้ว)
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // dispose: ถูกเรียกตอน provider ถูกทำลาย
  // ต้อง cancel stream เพื่อป้องกัน memory leak
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _conversationSubscription?.cancel();
    super.dispose();
  }
}
