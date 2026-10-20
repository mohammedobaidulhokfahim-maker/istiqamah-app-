import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../models/lifestyle_model.dart';
import '../models/prayer_model.dart';
import '../models/tasbih_model.dart';
import '../services/advisor_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

enum WorkField { english, ai, family, quran }

class AppController extends ChangeNotifier {
  AppController(this.storage, this.notifications);

  final StorageService storage;
  final NotificationService notifications;

  SharedPreferences get prefs => storage.prefs;

  late DateTime _today;
  late DayLog log;
  late DayMode mode;
  late Map<PrayerKind, JamahTime> jamah;

  DateTime? _sunlightStart;
  Timer? _poller;
  bool _hasVibrator = false;

  /// The root screen listens to this to open a tab from a notification.
  final ValueNotifier<int> requestedTab = ValueNotifier<int>(-1);

  // ---------------------------------------------------------------- setup

  Future<void> init() async {
    _hasVibrator = (await Vibration.hasVibrator()) == true;
    _loadToday();
    final ms = prefs.getInt('sunlight_start');
    if (ms != null) _sunlightStart = DateTime.fromMillisecondsSinceEpoch(ms);

    notifications.onForegroundResponse = handleResponse;
    await processPending();
    await _reschedule();

    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _tick());

    final launch = await notifications.launchResponse();
    if (launch != null) handleResponse(launch);
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  void _loadToday() {
    final n = DateTime.now();
    _today = DateTime(n.year, n.month, n.day);
    log = storage.getLog(dateKeyOf(_today));
    mode = SettingsStore.modeFor(_today, prefs);
    jamah = SettingsStore.loadJamah(prefs);
  }

  Future<void> _reschedule() =>
      notifications.rescheduleAll(prefs: prefs, logFor: (_) => log);

  Future<bool> requestPermissions() async {
    final ok = await notifications.requestPermissions();
    await _reschedule();
    return ok;
  }

  Future<void> _tick() async {
    var changed = false;
    if (dateKeyOf(DateTime.now()) != dateKeyOf(_today)) {
      _loadToday();
      changed = true;
      await _reschedule();
    }
    final had = await processPending();
    if (changed || had) notifyListeners();
  }

  Future<void> onAppResumed() async {
    await _tick();
    await _reschedule();
    notifyListeners();
  }

  /// "Done" taps from notifications arrive through SharedPreferences.
  Future<bool> processPending() async {
    await prefs.reload();
    final list = prefs.getStringList(SettingsStore.pendingKey) ?? <String>[];
    if (list.isEmpty) return false;
    await prefs.setStringList(SettingsStore.pendingKey, <String>[]);

    final touched = <HabitType>{};
    for (final entry in list) {
      final p = entry.split('|');
      if (p.length < 3) continue;
      final type = HabitType.values[int.parse(p[0])];
      final slot = int.parse(p[1]);
      final key = p[2];
      final target = key == log.dateKey ? log : storage.getLog(key);

      if (type == HabitType.jamah) {
        final kind = PrayerKind.values[slot];
        if (target.statusOf(kind) == PrayerStatus.none) {
          target.prayers[kind.name] = PrayerStatus.jamah.index;
        }
      } else if (type == HabitType.water) {
        target.waterGlasses += 1;
      }
      await storage.saveLog(target);
      touched.add(type);
    }
    await _cancelDoneSlots(touched);
    return true;
  }

  /// Notification tapped (or a button that opens the app).
  void handleResponse(NotificationResponse r) {
    final payload = r.payload;
    if (payload == null) return;
    final p = payload.split('|');
    if (p.length < 3) return;
    final type = HabitType.values[int.parse(p[0])];
    final slot = int.parse(p[1]);
    final day = parseDateKey(p[2]);

    if (type == HabitType.sunlight) requestedTab.value = 0;
    if (type == HabitType.tasbih) requestedTab.value = 1;

    if (r.actionId == 'done' &&
        (type == HabitType.sunlight || type == HabitType.tasbih)) {
      notifications.cancelSlot(day, type, slot);
    }
  }

  Future<void> _cancelDoneSlots(Set<HabitType> types) async {
    if (types.isEmpty) return;
    for (final s in ReminderSlot.build(jamah, mode)) {
      if (types.contains(s.type) && s.isDone(log, mode)) {
        await notifications.cancelSlot(_today, s.type, s.slot);
      }
    }
  }

  Future<void> _save({Set<HabitType> affects = const {}}) async {
    notifyListeners();
    await storage.saveLog(log);
    await _cancelDoneSlots(affects);
  }

  // ------------------------------------------------------------ schedule

  Set<int> get workDays => SettingsStore.workDays(prefs);

  Future<void> setTodayMode(DayMode m) async {
    await SettingsStore.setOverride(prefs, _today, m);
    mode = m;
    notifyListeners();
    await _reschedule();
  }

  Future<void> toggleWorkDay(int weekday) async {
    final days = SettingsStore.workDays(prefs);
    if (!days.add(weekday)) days.remove(weekday);
    await SettingsStore.saveWorkDays(prefs, days);
    mode = SettingsStore.modeFor(_today, prefs);
    notifyListeners();
    await _reschedule();
  }

  // -------------------------------------------------------------- prayers

  Future<void> setJamah(PrayerKind k, JamahTime t) async {
    await SettingsStore.saveJamah(prefs, k, t);
    jamah = SettingsStore.loadJamah(prefs);
    notifyListeners();
    await _reschedule();
  }

  Future<void> setPrayerStatus(PrayerKind k, PrayerStatus s) async {
    if (log.statusOf(k) == s) {
      log.prayers.remove(k.name); // tap again to clear
    } else {
      log.prayers[k.name] = s.index;
    }
    await _save(affects: {HabitType.jamah});
  }

  ({PrayerKind kind, DateTime time}) nextJamah() {
    final now = DateTime.now();
    for (final k in PrayerKind.values) {
      final t = jamah[k]!;
      final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      if (dt.isAfter(now)) return (kind: k, time: dt);
    }
    final t = jamah[PrayerKind.fajr]!;
    return (
      kind: PrayerKind.fajr,
      time: DateTime(now.year, now.month, now.day + 1, t.hour, t.minute)
    );
  }

  // ---------------------------------------------------------------- water

  Future<void> addWater(int delta) async {
    final v = log.waterGlasses + delta;
    log.waterGlasses = v < 0 ? 0 : v;
    await _save(affects: {HabitType.water});
  }

  // ------------------------------------------------------------- sunlight

  bool get sunlightRunning => _sunlightStart != null;

  int get sunlightSeconds =>
      log.outdoorSeconds +
      (_sunlightStart == null
          ? 0
          : DateTime.now().difference(_sunlightStart!).inSeconds);

  Future<void> toggleSunlight() async {
    if (_sunlightStart == null) {
      _sunlightStart = DateTime.now();
      await prefs.setInt(
          'sunlight_start', _sunlightStart!.millisecondsSinceEpoch);
      notifyListeners();
    } else {
      final secs = DateTime.now().difference(_sunlightStart!).inSeconds;
      _sunlightStart = null;
      await prefs.remove('sunlight_start');
      log.outdoorSeconds += secs;
      await _save(affects: {HabitType.sunlight});
    }
  }

  // --------------------------------------------------------------- tasbih

  void _feedback({required bool done}) {
    SystemSound.play(SystemSoundType.click);
    if (_hasVibrator) {
      Vibration.vibrate(duration: done ? 400 : 15);
    } else {
      done ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
    }
  }

  /// One tap on the counter. Saves immediately, so reaching 100 is auto-saved.
  Future<int> tapTasbih(Zikr z) async {
    final c = log.tasbihCount(z.id);
    if (c >= z.target) return c;
    final n = c + 1;
    log.tasbih[z.id] = n;
    _feedback(done: n == z.target);
    notifyListeners();
    unawaited(storage.saveLog(log));
    if (n == z.target) await _cancelDoneSlots({HabitType.tasbih});
    return n;
  }

  Future<void> resetTasbih(Zikr z) async {
    log.tasbih[z.id] = 0;
    await _save();
  }

  // ------------------------------------------------------ work / rest tabs

  Future<void> addMinutes(WorkField f, int delta) async {
    int clamp(int v) => v < 0 ? 0 : v;
    switch (f) {
      case WorkField.english:
        log.englishMinutes = clamp(log.englishMinutes + delta);
        break;
      case WorkField.ai:
        log.aiMinutes = clamp(log.aiMinutes + delta);
        break;
      case WorkField.family:
        log.familyMinutes = clamp(log.familyMinutes + delta);
        break;
      case WorkField.quran:
        log.quranMinutes = clamp(log.quranMinutes + delta);
        break;
    }
    await _save();
  }

  Future<void> setDuaRead({required bool morning, required bool value}) async {
    if (morning) {
      log.morningDua = value;
    } else {
      log.eveningDua = value;
    }
    await _save();
  }

  // ------------------------------------------------------------- insights

  DailyScore get score => computeScore(log, mode);

  List<AdviceCard> get advice => AdvisorService.evaluate(log, mode);

  List<MapEntry<DateTime, int>> history() {
    final out = <MapEntry<DateTime, int>>[];
    for (var i = 6; i >= 0; i--) {
      final d = _today.subtract(Duration(days: i));
      final l = i == 0 ? log : storage.getLog(dateKeyOf(d));
      out.add(MapEntry(d, computeScore(l, SettingsStore.modeFor(d, prefs)).total));
    }
    return out;
  }
}
