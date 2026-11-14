import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config.dart';
import '../bookings/models.dart';

final supabaseClientProvider = FutureProvider<SupabaseClient>((ref) async {
  if (!AppConfig.configured) {
    throw StateError(
      'Live mode needs SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY build configuration.',
    );
  }
  await Supabase.initialize(
    url: AppConfig.url,
    publishableKey: AppConfig.publishableKey,
  );
  return Supabase.instance.client;
});

final liveSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = await ref.watch(supabaseClientProvider.future);
  yield client.auth.currentSession;
  yield* client.auth.onAuthStateChange.map((event) => event.session);
});

final liveProfileProvider = FutureProvider<DemoPersona?>((ref) async {
  final session = await ref.watch(liveSessionProvider.future);
  if (session == null) return null;
  final client = await ref.watch(supabaseClientProvider.future);
  final row = await client
      .from('profiles')
      .select()
      .eq('id', session.user.id)
      .single();
  final role = row['role'] as String;
  if (role != 'customer' && role != 'technician') {
    throw StateError('Account role is unavailable.');
  }
  return DemoPersona(
    id: row['id'] as String,
    name: row['display_name'] as String,
    isTechnician: role == 'technician',
    technicianId: role == 'technician' ? row['id'] as String : null,
  );
});
