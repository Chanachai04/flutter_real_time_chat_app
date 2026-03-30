import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env.local");
  }

  static String get supabseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;
}
