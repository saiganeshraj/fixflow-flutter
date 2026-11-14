import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'errors/app_error.dart';

const int kStorageSchemaVersion = 1;
const String kSchemaVersionKey = 'fixflow_schema_version';
const String kBookingsKey = 'fixflow_bookings';
const String kActivePersonaKey = 'fixflow_active_persona';

/// Stores only fictional data; never credentials.
class LocalStorage {
  final SharedPreferences _prefs;
  LocalStorage(this._prefs);

  /// Null means a new workspace; an empty list is a valid saved workspace.
  List<Map<String, dynamic>>? loadBookingsRaw() {
    try {
      final version = _prefs.getInt(kSchemaVersionKey);
      final raw = _prefs.getString(kBookingsKey);
      if (raw == null) return null;
      if (version != kStorageSchemaVersion) {
        throw const FormatException('Unsupported schema');
      }
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      throw const PersistenceError(
        'Saved demo data cannot be read. Reset demo to restore fictional data.',
      );
    }
  }

  Future<void> saveBookingsRaw(List<Map<String, dynamic>> bookings) async {
    try {
      if (!await _prefs.setInt(kSchemaVersionKey, kStorageSchemaVersion) ||
          !await _prefs.setString(kBookingsKey, jsonEncode(bookings))) {
        throw StateError('Storage refused write');
      }
    } catch (_) {
      throw const PersistenceError(
        'Could not save the demo. Check browser storage and try again.',
      );
    }
  }

  String? loadActivePersonaId() {
    try {
      return _prefs.getString(kActivePersonaKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActivePersonaId(String id) async {
    await _prefs.setString(kActivePersonaKey, id);
  }

  Future<void> resetDemoData() async {
    for (final key in [kBookingsKey, kSchemaVersionKey, kActivePersonaKey]) {
      if (!await _prefs.remove(key)) {
        throw const PersistenceError(
          'Could not reset demo storage. Please retry.',
        );
      }
    }
  }
}
