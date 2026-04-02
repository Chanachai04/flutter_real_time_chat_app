import 'package:flutter/material.dart';
import 'package:flutter_real_time_chat_app/providers/auth_provider.dart';
import 'package:flutter_real_time_chat_app/providers/chat_provider.dart';
import 'package:flutter_real_time_chat_app/screens/chat_screen.dart';
import 'package:flutter_real_time_chat_app/screens/login_screen.dart';
import 'package:flutter_real_time_chat_app/screens/new_chat_screen.dart';
import 'package:flutter_real_time_chat_app/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // โหลด conversations ตอนเปิดหน้า
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    // ดึง ChatProvider
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // โหลดข้อมูล conversation ครั้งแรก
    await chatProvider.loadConversations();
    chatProvider.listenToConversations();
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // หยุด stream ก่อน logout (กัน memory leak)
    chatProvider.stopListeningToConversations();
    // logout user
    await authProvider.signOut();
    // ป้องกัน async error
    if (!mounted) return;
    // กลับไปหน้า login และลบ stack เดิม
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // listen state → ถ้า notifyListeners จะ rebuild
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        centerTitle: false,
        actions: [
          // ไปหน้า profile
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person),
          ),
          // logout
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: chatProvider.isLoading
            // กำลังโหลด ...
            ? Center(child: CircularProgressIndicator())
            // ไม่มี conversation
            : chatProvider.conversations.isEmpty
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
                      "No Conversations Yet",
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              )
            // มีข้อมูล → แสดง list
            : ListView.builder(
                itemCount: chatProvider.conversations.length,
                itemBuilder: (context, index) {
                  final conversation = chatProvider.conversations[index];
                  // user อีกฝั่ง
                  final otherUser = conversation.otherUser;
                  // ข้อความล่าสุด
                  final lastMessage = conversation.lastMessage;

                  return ListTile(
                    // avatar
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,

                      child: otherUser?.avatarUrl != null
                          // มีรูป → แสดงรูป
                          ? ClipOval(
                              child: Image.network(
                                otherUser!.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              ),
                            )
                          // ไม่มีรูป → ใช้อักษรตัวแรก
                          : Text(
                              otherUser?.username[0].toUpperCase() ?? '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    // username
                    title: Text(
                      otherUser?.username ?? 'Unknown User',
                      // ถ้ามี unread → ทำตัวหนา
                      style: TextStyle(
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    // ข้อความล่าสุด
                    subtitle: lastMessage != null
                        ? Text(
                            lastMessage.content,
                            maxLines: 1, // ตัดบรรทัดเดียว
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(),
                          )
                        : Text("No Messages Yet"),
                    // ด้านขวา (เวลา + unread)
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // เวลา message ล่าสุด
                        if (lastMessage != null)
                          Text(
                            timeago.format(lastMessage.createdAt, locale: 'th'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        // สัญลักษณ์ unread
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // ไปหน้า chat
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            conversationId: conversation.id,
                            otherUser: otherUser!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      // ปุ่มสร้าง chat ใหม่
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewChatScreen()),
          );
        },
        child: Icon(Icons.add_comment),
      ),
    );
  }

  @override
  void dispose() {
    // หยุด stream ตอน widget ถูกทำลาย (กัน memory leak)
    final chatprovider = Provider.of<ChatProvider>(context, listen: false);
    chatprovider.stopListeningToConversations();
    super.dispose();
  }
}
