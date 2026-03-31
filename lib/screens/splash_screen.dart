import 'package:flutter/material.dart';
import 'package:flutter_real_time_chat_app/providers/auth_provider.dart';
import 'package:flutter_real_time_chat_app/screens/home_screen.dart';
import 'package:flutter_real_time_chat_app/screens/login_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // หน่วงเวลา 2 วินาที
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;
    // ดึง AuthProvider โดยไม่ subscribe การเปลี่ยนแปลง (listen: false)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // เช็คสถานะว่าผู้ใช้ login อยู่หรือไม่
    if (authProvider.isAuthenticated) {
      // ถ้า login แล้ว → ไปหน้า Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // ถ้ายังไม่ login → ไปหน้า Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Chat App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
