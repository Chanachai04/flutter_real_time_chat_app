import 'package:flutter/material.dart';
import 'package:flutter_real_time_chat_app/providers/auth_provider.dart';
import 'package:flutter_real_time_chat_app/providers/chat_provider.dart';
import 'package:flutter_real_time_chat_app/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_real_time_chat_app/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.init();

  await Supabase.initialize(
    url: SupabaseConfig.supabseUrl,
    anonKey: SupabaseConfig.supabseAnonKey,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // inject provider หลายตัวให้ widget tree ทั้งหมดใช้ได้
      providers: [
        // จัดการ state authentication
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // จัดการ state chat (conversations, realtime updates)
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        // ปิด debug banner
        debugShowCheckedModeBanner: false,
        // theme สำหรับ light mode
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // ตั้งค่า AppBar default
          appBarTheme: AppBarTheme(centerTitle: true, elevation: 0),
          // style ของ input field (TextField, TextFormField)
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          // style ของ ElevatedButton
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // theme สำหรับ dark mode
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(centerTitle: true, elevation: 0),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: Colors.grey[800],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // ใช้ theme ตาม system (light/dark ตามเครื่องผู้ใช้)
        themeMode: ThemeMode.system,
        // หน้าแรกของแอป
        home: SplashScreen(),
      ),
    );
  }
}
