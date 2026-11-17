import 'package:supabase_flutter/supabase_flutter.dart';

typedef ProfileData = Map<String, dynamic>;

class ProfileService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan masuk kembali.');
    }
    return user.id;
  }

  static Future<ProfileData> getMitraProfile() async {
    final userData = await _client
        .from('users')
        .select('id, name, email, phone')
        .eq('id', _userId)
        .single();

    final consumerData = await _client
        .from('consumer_profiles')
        .select('id, cafe_name, address, latitude, longitude')
        .eq('user_id', _userId)
        .maybeSingle();

    return {
      'user': userData,
      'consumer': consumerData ?? {},
    };
  }

  static Future<void> updateProfileAndContact({
    required String name,
    required String phone,
    required String cafeName,
  }) async {
    await _client.from('users').update({
      'name': name,
      'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId);

    await _client.from('consumer_profiles').upsert({
      'user_id': _userId,
      'cafe_name': cafeName,
    }, onConflict: 'user_id');
  }

  static Future<void> updateDeliveryAddress({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    await _client.from('consumer_profiles').upsert({
      'user_id': _userId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    }, onConflict: 'user_id');
  }
}