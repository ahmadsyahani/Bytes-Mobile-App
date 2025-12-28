import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign Up Logic
  Future<String?> signUp({
    required String email,
    required String password,
    required String nrp,
  }) async {
    try {
      // 1. Cek Whitelist
      final whitelistData = await _supabase
          .from('whitelist')
          .select()
          .eq('nrp', nrp)
          .single(); // Error kalau data gak ada

      if (whitelistData['is_registered'] == true) {
        return "NRP sudah terdaftar!";
      }

      String fullName = whitelistData['full_name'];

      // 2. Daftar ke Auth Supabase
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) return "Gagal mendaftar.";

      // 3. Simpan Data ke Tabel Profiles
      await _supabase.from('profiles').insert({
        'id': res.user!.id,
        'nrp': nrp,
        'email': email,
        'full_name': fullName,
        'photo_url': null,
      });

      // 4. Update Whitelist jadi true
      await _supabase
          .from('whitelist')
          .update({'is_registered': true})
          .eq('nrp', nrp);

      return null; // Sukses
    } on PostgrestException catch (e) {
      return "Data NRP tidak ditemukan: ${e.message}";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // Login Logic
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null; // Sukses
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Login gagal: $e";
    }
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
