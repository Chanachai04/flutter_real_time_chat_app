import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_real_time_chat_app/models/user_model.dart';
import 'package:flutter_real_time_chat_app/providers/auth_provider.dart';
import 'package:flutter_real_time_chat_app/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  // id ของ conversation ใช้โหลด message
  final String conversationId;
  // user ที่เราคุยด้วย (อีกฝั่ง)
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // controller สำหรับ input message
  final _messageController = TextEditingController();
  // controller สำหรับ scroll list message
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // โหลด message ครั้งแรก + subscribe realtime
    _loadMessages();
  }

  @override
  void dispose() {
    // ปล่อย resource ป้องกัน memory leak
    _messageController.dispose();
    _scrollController.dispose();
    // หยุด realtime listener
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.stopListeningToMessages();
    super.dispose();
  }

  // โหลด message + start realtime
  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // โหลด message จาก backend
    await chatProvider.loadMessages(widget.conversationId);
    // subscribe realtime message
    chatProvider.listenToMessages(widget.conversationId);
    // scroll ลงล่างสุด
    _scrollToButtom();
  }

  // scroll ไป message ล่าสุด
  void _scrollToButtom() {
    if (_scrollController.hasClients) {
      // delay เพื่อรอ build UI ก่อน
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ส่ง message
  Future<void> _sendMessages() async {
    // กันส่งข้อความว่าง
    if (_messageController.text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final message = _messageController.text.trim();
    // clear input ทันที (UX ลื่นขึ้น)
    _messageController.clear();
    // clear input ทันที (UX ลื่นขึ้น)
    final success = await chatProvider.sendMessage(
      widget.conversationId,
      message,
    );

    if (success) {
      // scroll ลงล่างหลังส่ง
      _scrollToButtom();
    } else {
      // ถ้า widget ยังอยู่ → แสดง error
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send message")));
    }
  }

  // ถ้า widget ยังอยู่ → แสดง error
  String _formatMessageTimer(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return "${time.day}/${time.month}/${time.year}";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour(s) ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minute(s) ago";
    } else {
      return "Just now";
    }
  }

  @override
  Widget build(BuildContext context) {
    // provider auth (เอา user ปัจจุบัน)
    final authProvider = Provider.of<AuthProvider>(context);
    // provider chat (messages + loading state)
    final chatProvider = Provider.of<ChatProvider>(context);
    // id ของ user ปัจจุบัน
    final currentuserId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        // header แสดง avatar + username
        title: Row(
          children: [
            // avatar
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 18,
              child: widget.otherUser.avatarUrl != null
                  // มีรูป → แสดงรูป
                  ? ClipOval(
                      child: Image.network(
                        widget.otherUser.avatarUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  // ไม่มีรูป → ใช้อักษรตัวแรก
                  : Text(
                      widget.otherUser.username[0].toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
            ),
            SizedBox(width: 12),
            // username + fullname
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.username,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // แสดง fullname ถ้ามี
                  if (widget.otherUser.fullName != null &&
                      widget.otherUser.fullName!.isNotEmpty)
                    Text(
                      widget.otherUser.fullName!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ===== message list =====
          Expanded(
            child: chatProvider.isLoading
                // loading state
                ? CircularProgressIndicator()
                : chatProvider.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No Message Found",
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Start the conversation",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                // มี message → แสดง list
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      // เช็คว่า message นี้เป็นของเราหรือเปล่า
                      final isSentByMe = message.senderId == currentuserId;
                      // แสดง date separator เมื่อวันเปลี่ยน
                      final showDateSeperator =
                          index == 0 ||
                          !_isSameDay(
                            chatProvider.messages[index - 1].createdAt,
                            message.createdAt,
                          );
                      return Column(
                        children: [
                          // ===== วันที่ (Today / Yesterday / etc.) =====
                          if (showDateSeperator)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _formatDateSeparator(message.createdAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                          // ===== bubble message =====
                          Align(
                            alignment: isSentByMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              // จำกัดความกว้าง bubble
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isSentByMe
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // เนื้อ message
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isSentByMe
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  // เวลา message
                                  Text(
                                    _formatMessageTimer(message.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isSentByMe
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // ===== input message =====
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                // เงาด้านบน
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // input field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                    ),
                    maxLines: null, // multiline// multiline
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 8),
                // ปุ่ม send
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    onPressed: _sendMessages,
                    icon: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // เช็คว่าอยู่วันเดียวกันไหม
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // เช็คว่าอยู่วันเดียวกันไหม
  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (_isSameDay(date, now)) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
