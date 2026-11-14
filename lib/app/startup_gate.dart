import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_screen.dart';
import '../features/auth/live_providers.dart';
import '../core/widgets/loading_error_empty.dart';
import 'config.dart';
import 'providers.dart';

class StartupGate extends ConsumerWidget {
  final Widget child;
  const StartupGate({super.key, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.isLive) {
      if (!AppConfig.configured) {
        return const Scaffold(
          body: ErrorState(
            message: 'Live mode is not configured. See docs/BACKEND.md for SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY. Build without APP_MODE=live to use the independent demo.',
          ),
        );
      }
      final client = ref.watch(supabaseClientProvider);
      if (client.isLoading) {
        return const Scaffold(
          body: LoadingState(message: 'Connecting accounts…'),
        );
      }
      if (client.hasError) {
        return Scaffold(
          body: ErrorState(
            message: 'Account service unavailable.',
            onRetry: () => ref.invalidate(supabaseClientProvider),
          ),
        );
      }
      final session = ref.watch(liveSessionProvider);
      if (session.isLoading) {
        return const Scaffold(
          body: LoadingState(message: 'Restoring session…'),
        );
      }
      if (session.hasError) {
        return Scaffold(
          body: ErrorState(
            message: 'Could not restore session.',
            onRetry: () => ref.invalidate(liveSessionProvider),
          ),
        );
      }
      if (session.valueOrNull == null) return const AuthScreen();
      final profile = ref.watch(liveProfileProvider);
      if (profile.isLoading) {
        return const Scaffold(
          body: LoadingState(message: 'Loading your profile…'),
        );
      }
      if (profile.hasError || profile.valueOrNull == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load your account profile.'),
                TextButton(
                  onPressed: () => ref.invalidate(liveProfileProvider),
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => client.requireValue.auth.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        );
      }
    }
    ref.watch(repositoryListenerProvider);
    return ref
        .watch(repoInitProvider)
        .when(
          data: (_) => child,
          loading: () => const Scaffold(
            body: LoadingState(message: 'Opening your workspace…'),
          ),
          error: (error, _) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          if (!AppConfig.isLive) {
                            await ref.read(demoRepositoryProvider).reset();
                          }
                          ref.invalidate(repoInitProvider);
                        } catch (_) {
                          // Keep the recovery screen available if storage is still unavailable.
                          ref.invalidate(repoInitProvider);
                        }
                      },
                      child: Text(AppConfig.isLive ? 'Retry' : 'Reset demo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}
