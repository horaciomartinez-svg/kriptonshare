// lib/core/network/supabase_client.dart
// Punto de acceso tipado al cliente Supabase.

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  static SupabaseClient get client => Supabase.instance.client;
}
