import 'package:flutter/material.dart';
import 'package:flutter_real_time_chat_app/providers/auth_provider.dart';
import 'package:flutter_real_time_chat_app/screens/home_screen.dart';
import 'package:flutter_real_time_chat_app/screens/signup_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey สำหรับอ้างอิงและควบคุม Form ใช้เรียก validate(), save(), reset() ของฟอร์ม
  final _formKey = GlobalKey<FormState>();
  // Controller สำหรับ input email ใช้ดึงค่าที่ user พิมพ์ และควบคุม TextField
  final _emailController = TextEditingController();
  // Controller สำหรับ input password
  final _passwordController = TextEditingController();
  // state สำหรับ toggle แสดง/ซ่อน password
  bool _obsecurePassword = true;

  @override
  void dispose() {
    // ล้าง resource ของ controller เมื่อ widget ถูกทำลาย
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // ตรวจสอบความถูกต้องของ form (เช่น email format, required field) ถ้าไม่ผ่านจะหยุดทำงานทันที
    if (!_formKey.currentState!.validate()) return;
    // ดึง AuthProvider โดยไม่ subscribe การเปลี่ยนแปลง
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // เรียก API login ผ่าน provider
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    // ตรวจสอบว่า widget ยังอยู่ใน tree หรือไม่ (กัน async error)
    if (!mounted) return;

    if (success) {
      // login สำเร็จ → ไปหน้า Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // login ไม่สำเร็จ → แสดง error ผ่าน SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Login to continue chatting with your friends',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 32),
                  // input email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    // validate email
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      // ตรวจสอบรูปแบบ email ด้วย regex
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // input password
                  TextFormField(
                    controller: _passwordController,
                    // ซ่อน/แสดง password
                    obscureText: _obsecurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      // ปุ่ม toggle password
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obsecurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obsecurePassword = !_obsecurePassword;
                          });
                        },
                      ),
                    ),
                    // validate password
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),
                  // Consumer ใช้ฟัง state ของ AuthProvider
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return ElevatedButton(
                        // ถ้า loading → disable ปุ่ม
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _login(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        // ถ้า loading → แสดง spinner
                        child: authProvider.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Login'),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          // ไปหน้า signup
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignupScreen(),
                            ),
                          );
                        },
                        child: Text("Sign Up"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
