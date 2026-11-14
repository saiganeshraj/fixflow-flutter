import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import '../core/storage.dart';
import '../demo/demo_repository.dart';
import '../demo/fixtures.dart';
import '../features/bookings/models.dart';
import '../features/bookings/live_repository.dart';
import '../features/catalog/repository.dart';
import '../features/catalog/catalog_state.dart';
import '../features/auth/live_providers.dart';
import 'config.dart';

final repositoryProvider = Provider<AppRepository>((ref) {
  if (!AppConfig.isLive) return ref.watch(demoRepositoryProvider);
  ref.watch(liveSessionProvider.select((state) => state.valueOrNull?.user.id));
  final repo = LiveRepository(ref.watch(supabaseClientProvider).requireValue);
  ref.onDispose(repo.dispose);
  return repo;
});

final currentPersonaProvider = Provider<DemoPersona>(
  (ref) => AppConfig.isLive
      ? ref.watch(liveProfileProvider).requireValue!
      : ref.watch(activePersonaProvider),
);

final bookingCustomerIdProvider = Provider<String>((ref) {
  final persona = ref.watch(currentPersonaProvider);
  return !AppConfig.isLive && persona.isTechnician
      ? DemoFixtures.customerAId
      : persona.id;
});

// ─── Infrastructure providers ─────────────────────────────────────────────────

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'SharedPreferences must be overridden in ProviderScope.',
  ),
);

final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
});

final demoRepositoryProvider = Provider<DemoRepository>((ref) {
  final clock = ref.watch(clockProvider);
  final storage = ref.watch(localStorageProvider);
  final repo = DemoRepository(clock: clock, storage: storage);
  ref.onDispose(repo.dispose);
  return repo;
});

final repositoryRevisionProvider = StateProvider<int>((ref) => 0);

final repositoryListenerProvider = Provider<void>((ref) {
  final repo = ref.watch(repositoryProvider);
  void changed() {
    ref.read(repositoryRevisionProvider.notifier).state++;
  }

  repo.addListener(changed);
  ref.onDispose(() => repo.removeListener(changed));
});

// Initialization state — resolved once at startup.
final repoInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(repositoryProvider);
  await repo.initialize();
});

// ─── Catalog providers ────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  await ref.watch(repoInitProvider.future);
  final repo = ref.watch(repositoryProvider);
  return repo.fetchCategories();
});

final servicesProvider = FutureProvider<List<Service>>((ref) async {
  await ref.watch(repoInitProvider.future);
  final repo = ref.watch(repositoryProvider);
  return repo.fetchServices();
});

final serviceProvider = FutureProvider.family<Service?, String>((
  ref,
  id,
) async {
  await ref.watch(repoInitProvider.future);
  final repo = ref.watch(repositoryProvider);
  return repo.fetchService(id);
});

// Derive the view from cached data: typing/filtering never refetches the catalog.
final filteredServicesProvider = Provider<AsyncValue<List<Service>>>((ref) {
  final filters = ref.watch(catalogFiltersProvider);
  return ref.watch(servicesProvider).whenData((all) {
    final query = filters.query.trim().toLowerCase();
    final matches = all
        .where(
          (service) =>
              (filters.categoryId == null ||
                  service.categoryId == filters.categoryId) &&
              (query.isEmpty ||
                  '${service.title} ${service.description}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
    if (filters.sort != ServiceSort.recommended) {
      matches.sort((a, b) {
        final price = filters.sort == ServiceSort.priceLow
            ? a.pricePaise.compareTo(b.pricePaise)
            : b.pricePaise.compareTo(a.pricePaise);
        return price == 0 ? a.title.compareTo(b.title) : price;
      });
    }
    return List.unmodifiable(matches);
  });
});

// ─── Demo persona providers ────────────────────────────────────────────────────

final activePersonaProvider =
    StateNotifierProvider<ActivePersonaNotifier, DemoPersona>(
      (ref) => ActivePersonaNotifier(ref),
    );

class ActivePersonaNotifier extends StateNotifier<DemoPersona> {
  final Ref _ref;

  ActivePersonaNotifier(this._ref) : super(DemoFixtures.personas.first) {
    restoreFromStorage();
  }

  void switchTo(DemoPersona persona) {
    state = persona;
    _ref.read(localStorageProvider).saveActivePersonaId(persona.id);
  }

  void restoreFromStorage() {
    final storage = _ref.read(localStorageProvider);
    final id = storage.loadActivePersonaId();
    if (id != null) {
      final found = DemoFixtures.personas.where((p) => p.id == id).firstOrNull;
      if (found != null) state = found;
    }
  }
}

// ─── Booking providers ────────────────────────────────────────────────────────

final customerBookingsProvider = StreamProvider.autoDispose
    .family<List<Booking>, String>((ref, customerId) {
      final repo = ref.watch(repositoryProvider);
      return repo.watchCustomerBookings(customerId);
    });

/// Recomputes from the same scoped booking stream used by My Bookings.
/// No duplicate counters to synchronize when a technician changes a booking.
final bookingOverviewProvider =
    Provider.autoDispose<AsyncValue<BookingOverview>>((ref) {
      final customerId = ref.watch(bookingCustomerIdProvider);
      return ref
          .watch(customerBookingsProvider(customerId))
          .whenData(BookingOverview.fromBookings);
    });

class BookingOverview {
  final int upcomingCount;
  final int completedCount;
  final Booking? nextBooking;
  const BookingOverview(
    this.upcomingCount,
    this.completedCount,
    this.nextBooking,
  );

  factory BookingOverview.fromBookings(List<Booking> bookings) {
    final upcoming = bookings.where((b) => !b.status.isTerminal).toList()
      ..sort((a, b) => a.slotStartUtc.compareTo(b.slotStartUtc));
    return BookingOverview(
      upcoming.length,
      bookings.where((b) => b.status == BookingStatus.completed).length,
      upcoming.firstOrNull,
    );
  }
}

final bookingDetailProvider = FutureProvider.autoDispose
    .family<Booking?, String>((ref, bookingId) async {
      await ref.watch(repoInitProvider.future);
      ref.watch(repositoryRevisionProvider);
      final repo = ref.watch(repositoryProvider);
      return repo.fetchBooking(bookingId);
    });

final availableSlotsProvider = FutureProvider.autoDispose
    .family<List<DateTime>, String>((ref, serviceId) async {
      ref.watch(repositoryRevisionProvider);
      final repo = ref.watch(repositoryProvider);
      await ref.watch(repoInitProvider.future);
      return repo.fetchAvailableSlots(serviceId);
    });

// ─── Technician providers ─────────────────────────────────────────────────────

final technicianBookingsProvider = StreamProvider.autoDispose
    .family<List<Booking>, String>((ref, techId) {
      final repo = ref.watch(repositoryProvider);
      return repo.watchTechnicianBookings(techId);
    });

final technicianListProvider = FutureProvider<List<Technician>>((ref) async {
  ref.watch(repositoryRevisionProvider);
  await ref.watch(repoInitProvider.future);
  final repo = ref.watch(repositoryProvider);
  return repo.fetchTechnicians();
});
