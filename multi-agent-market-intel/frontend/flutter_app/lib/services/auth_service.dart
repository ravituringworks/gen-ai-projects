import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static Future<void> init({required String url, required String anonKey}) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
  static SupabaseClient get client => Supabase.instance.client;
}
