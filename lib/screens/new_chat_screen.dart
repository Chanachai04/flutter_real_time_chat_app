import 'package:flutter/material.dart';
import 'package:flutter_real_time_chat_app/models/user_model.dart';
import 'package:flutter_real_time_chat_app/providers/chat_provider.dart';
import 'package:flutter_real_time_chat_app/screens/chat_screen.dart';
import 'package:provider/provider.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  // controller สำหรับ TextField (search input)
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // โหลด user ทั้งหมดตอนเปิดหน้า
    _loadUsers();
  }

  @override
  void dispose() {
    // ป้องกัน memory leak (ต้อง dispose controller)
    _searchController.dispose();
    super.dispose();
  }

  // โหลด user ทั้งหมดจาก provider
  Future<void> _loadUsers() async {
    final chatprovider = Provider.of<ChatProvider>(context, listen: false);
    await chatprovider.loadAllUsers();
  }

  // search user ตาม keyword
  Future<void> _searchUsers(String query) async {
    final chatprovider = Provider.of<ChatProvider>(context, listen: false);
    await chatprovider.searchUsers(query);
  }

  // เริ่ม chat กับ user ที่เลือก
  Future<void> _startChat(UserModel user) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // แสดง loading dialog กัน user กดซ้ำ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    // ขอ conversationId (มีอยู่แล้วจะใช้ของเดิม / ไม่มีจะสร้างใหม่)
    final conversationId = await chatProvider.getOrCreateConversation(user.id);
    // เช็คว่า widget ยังอยู่ใน tree ไหม (กัน crash)
    if (!mounted) return;
    // ปิด dialog loading
    Navigator.pop(context); // ปิด loading dialog

    if (conversationId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(conversationId: conversationId, otherUser: user),
        ),
      );
    } else {
      // ถ้าสร้าง conversation ไม่สำเร็จ → แจ้ง error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create conversation"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // listen: true → rebuild UI ทุกครั้งที่ provider เปลี่ยนแปลง (เช่น กำลังโหลด, มี error, ได้ user มาใหม่)
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("New Chat"), centerTitle: false),
      body: Column(
        children: [
          // ===== search bar =====
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: Icon(Icons.search),
                // ปุ่ม clear (แสดงเมื่อมี text)
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear(); // ล้าง input
                          _loadUsers(); // โหลด user ทั้งหมดใหม่
                        },
                        icon: Icon(Icons.clear),
                      )
                    : null,
              ),
              // trigger ทุกครั้งที่พิมพ์
              onChanged: (value) {
                if (value.isEmpty) {
                  // ถ้า input ว่าง → โหลดทั้งหมด
                  _loadUsers();
                } else {
                  // ถ้ามีค่า → search
                  _searchUsers(value);
                }
              },
            ),
          ),
          // ===== list user =====
          Expanded(
            child: chatProvider.isLoading
                // loading state
                ? Center(child: CircularProgressIndicator())
                // ไม่มี user
                : chatProvider.users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 80,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No Users Found",
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                // มี user → แสดง list
                : ListView.builder(
                    itemCount: chatProvider.users.length,
                    itemBuilder: (context, index) {
                      final user = chatProvider.users[index];

                      return ListTile(
                        // avatar
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,

                          child: user?.avatarUrl != null
                              // มีรูป → แสดงรูป
                              ? ClipOval(
                                  child: Image.network(
                                    user!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                  ),
                                )
                              // ไม่มีรูป → ใช้อักษรตัวแรก
                              : Text(
                                  user?.username[0].toUpperCase() ?? '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        // username
                        title: Text(user.username),
                        // fullname
                        subtitle:
                            user.fullName != null && user.fullName!.isNotEmpty
                            ? Text(user.fullName!)
                            : null,
                        // icon ด้านขวา
                        trailing: Icon(Icons.chat_bubble_outline),
                        // ไปหน้า chat เมื่อกด
                        onTap: () => _startChat(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
