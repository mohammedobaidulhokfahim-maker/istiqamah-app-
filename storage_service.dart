import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lifestyle_model.dart';
import '../models/prayer_model.dart';

/// Daily logs live in Hive. Small settings live in SharedPreferences so the
/// background isolates (notification buttons, alarm manager) can read them
/// without touching the Hive box.
class StorageService {
  StorageService._(this._box, this.prefs);

  final Box _box;
  final SharedPreferences prefs;

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox('day_logs');
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(box, prefs);
  }

  DayLog getLog(String dateKey) {
    final raw = _box.get(dateKey);
    if (raw is Map) return DayLog.fromMap(raw);
    return DayLog(dateKey: dateKey);
  }

  Future<void> saveLog(DayLog log) => _box.put(log.dateKey, log.toMap());

  Future<void> deleteLog(String dateKey) => _box.delete(dateKey);
}

class SettingsStore {
  static const pendingKey = 'pending_actions';
  static const _overrideKey = 'mode_override';
  static const _workDaysKey = 'work_days';

  /// Dart weekday numbers: Mon=1 ... Sun=7. Default work week: Sun-Thu.
  static const List<int> defaultWorkDays = [7, 1, 2, 3, 4];

  static Map<PrayerKind, JamahTime> loadJamah(SharedPreferences p) {
    final out = <PrayerKind, JamahTime>{};
    for (final k in PrayerKind.values) {
      final raw = p.getString('jamah_${k.name}');
      out[k] = raw == null ? defaultJamah[k]! : JamahTime.parse(raw);
    }
    return out;
  }

  static Future<void> saveJamah(
          SharedPreferences p, PrayerKind k, JamahTime t) =>
      p.setString('jamah_${k.name}', t.encode());

  static Set<int> workDays(SharedPreferences p) {
    final raw = p.getStringList(_workDaysKey);
    if (raw == null) return defaultWorkDays.toSet();
    return raw.map(int.parse).toSet();
  }

  static Future<void> saveWorkDays(SharedPreferences p, Set<int> days) =>
      p.setStringList(_workDaysKey, days.map((e) => e.toString()).toList());

  static DayMode modeFor(DateTime day, SharedPreferences p) {
    final ov = p.getString(_overrideKey);
    if (ov != null) {
      final parts = ov.split('|');
      if (parts.length == 2 && parts[0] == dateKeyOf(day)) {
        return parts[1] == 'rest' ? DayMode.rest : DayMode.work;
      }
    }
    return workDays(p).contains(day.weekday) ? DayMode.work : DayMode.rest;
  }

  static Future<void> setOverride(
          SharedPreferences p, DateTime day, DayMode m) =>
      p.setString(_overrideKey, '${dateKeyOf(day)}|${m.name}');

  /// Called from the background isolate when "Done" is tapped.
  static Future<void> addPending(SharedPreferences p, String entry) async {
    await p.reload();
    final list = List<String>.from(p.getStringList(pendingKey) ?? <String>[]);
    list.add(entry);
    await p.setStringList(pendingKey, list);
  }
}
