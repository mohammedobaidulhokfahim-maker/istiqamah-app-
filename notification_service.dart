import 'dart:typed_data';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/lifestyle_model.dart';
import '../models/prayer_model.dart';
import '../models/tasbih_model.dart';
import 'storage_service.dart';

/// Unique, stable id for one notification:
/// (day) + (habit type) + (slot) + (attempt 0-3 nags, 5-7 snooze nags).
int notifId(DateTime day, HabitType type, int slot, int attempt) =>
    (dayIndexOf(day) % 1000) * 1000 +
    (type.index + 1) * 100 +
    slot * 10 +
    attempt;

/// One reminder in the day (e.g. "Dhuhr pre-jamah alarm", "3rd glass of water").
/// If the habit is not done, it repeats every 5 minutes, [attempts] times in total.
class ReminderSlot {
  ReminderSlot({
    required this.type,
    required this.slot,
    required this.minuteOfDay,
    required this.title,
    required this.body,
    required this.isDone,
    this.attempts = 4, // 1 first alert + 3 nags
    this.opensApp = false,
    this.hasActions = true,
  });

  final HabitType type;
  final int slot;
  final int minuteOfDay;
  final String title;
  final String body;
  final bool Function(DayLog, DayMode) isDone;
  final int attempts;
  final bool opensApp;
  final bool hasActions;

  DateTime timeFor(DateTime day, int attempt) => DateTime(
      day.year, day.month, day.day, 0, minuteOfDay + attempt * 5);

  String bodyFor(int attempt) =>
      attempt == 0 ? body : 'আবার মনে করিয়ে দিচ্ছি: $body';

  String payload(DateTime day) => '${type.index}|$slot|${dateKeyOf(day)}';

  static const List<int> _waterHours = [8, 10, 12, 14, 16, 18, 20, 21];
  static const List<int> _standMinutes = [600, 720, 870, 1020, 1170];

  static List<ReminderSlot> build(
      Map<PrayerKind, JamahTime> jamah, DayMode mode) {
    final out = <ReminderSlot>[];

    // 1) Pre-jamah alarm: 10 minutes before each jamah.
    for (final k in PrayerKind.values) {
      final t = jamah[k]!;
      final start = t.minutesOfDay - 10 < 0 ? 0 : t.minutesOfDay - 10;
      out.add(ReminderSlot(
        type: HabitType.jamah,
        slot: k.index,
        minuteOfDay: start,
        title: '${k.bn} জামাতের ১০ মিনিট বাকি',
        body:
            '${k.bn} জামাত ${t.label} এ। ওযু করে প্রস্তুত হও। জামাতে পড়লে Done চাপো।',
        isDone: (log, m) => log.statusOf(k) != PrayerStatus.none,
      ));
    }

    // 2) Water: glass number (i+1) should be finished by slot i.
    for (var i = 0; i < _waterHours.length; i++) {
      out.add(ReminderSlot(
        type: HabitType.water,
        slot: i,
        minuteOfDay: _waterHours[i] * 60,
        title: 'পানি খাওয়ার সময়',
        body:
            'এই সময়ের মধ্যে অন্তত ${toBn(i + 1)} গ্লাস খাওয়ার কথা। এক গ্লাস পানি খাও, তারপর Done চাপো।',
        isDone: (log, m) => log.waterGlasses >= i + 1,
      ));
    }

    // 3) Sunlight / fresh air.
    const sunMinutes = [420, 990]; // 07:00 and 16:30
    for (var i = 0; i < sunMinutes.length; i++) {
      out.add(ReminderSlot(
        type: HabitType.sunlight,
        slot: i,
        minuteOfDay: sunMinutes[i],
        title: 'রোদে ও খোলা বাতাসে যাওয়ার সময়',
        body: 'ঘরে বসে থেকো না। এখনই বাইরে গিয়ে স্টপওয়াচ চালু করো।',
        opensApp: true,
        isDone: (log, m) =>
            log.outdoorSeconds >= Targets.outdoorMinutes(m) * 60,
      ));
    }

    // 4) Tasbih.
    out.add(ReminderSlot(
      type: HabitType.tasbih,
      slot: 0,
      minuteOfDay: 1230, // 20:30
      title: 'তাসবিহের সময়',
      body: 'আজকের চারটি জিকির (১০০ বার করে) এখনো বাকি আছে।',
      opensApp: true,
      isDone: (log, m) => log.allZikrsDone,
    ));

    // 5) Stand-up nudges (single alert, no nagging).
    for (var i = 0; i < _standMinutes.length; i++) {
      out.add(ReminderSlot(
        type: HabitType.stand,
        slot: i,
        minuteOfDay: _standMinutes[i],
        title: 'উঠে দাঁড়াও',
        body: 'অনেকক্ষণ বসে বা শুয়ে আছো? উঠে ৫ মিনিট হাঁটো, শরীর টানটান করো।',
        attempts: 1,
        hasActions: false,
        isDone: (log, m) => false,
      ));
    }
    return out;
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleBackgroundResponse(response);
}

/// Runs every ~12 hours from android_alarm_manager_plus, even if the app is closed.
/// Keeps the next few days of notifications scheduled.
@pragma('vm:entry-point')
Future<void> alarmRefreshCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final svc = NotificationService.instance;
  await svc.init(background: true);
  await svc.rescheduleAll(
      prefs: prefs, logFor: null, daysAhead: 4, includeToday: false);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set by the controller. Called when the user taps a notification
  /// (or a button that opens the app) while the app is running.
  void Function(NotificationResponse response)? onForegroundResponse;

  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init({bool background = false}) async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();
    var zone = prefs.getString('tz_name') ?? 'Asia/Dhaka';
    if (!background) {
      try {
        zone = await FlutterTimezone.getLocalTimezone();
        await prefs.setString('tz_name', zone);
      } catch (_) {}
    }
    try {
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) => onForegroundResponse?.call(r),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _ready = true;
  }

  /// Android 13+ notification permission and Android 12+ exact alarm permission.
  Future<bool> requestPermissions() async {
    final a = _android;
    final notif = await a?.requestNotificationsPermission();
    await a?.requestExactAlarmsPermission();
    return notif ?? true;
  }

  Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  Future<NotificationResponse?> launchResponse() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d != null && d.didNotificationLaunchApp) return d.notificationResponse;
    return null;
  }

  Future<AndroidScheduleMode> _scheduleMode() async => await canScheduleExact()
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  NotificationDetails _details(ReminderSlot s, String body) {
    final isJamah = s.type == HabitType.jamah;
    final actions = s.hasActions
        ? <AndroidNotificationAction>[
            AndroidNotificationAction('done', 'Done',
                showsUserInterface: s.opensApp, cancelNotification: true),
            const AndroidNotificationAction('snooze', 'Snooze 10m',
                showsUserInterface: false, cancelNotification: true),
          ]
        : null;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        isJamah ? 'jamah_alarm_v1' : 'habit_nag_v1',
        isJamah ? 'Jamah alarms' : 'Habit reminders',
        channelDescription: isJamah
            ? 'Loud alarm 10 minutes before each jamah'
            : 'Water, sunlight, tasbih and stand-up reminders',
        importance: Importance.max,
        priority: Priority.high,
        category: isJamah
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        audioAttributesUsage:
            isJamah ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        playSound: true,
        enableVibration: true,
        autoCancel: !isJamah,
        // 4 = FLAG_INSISTENT: the alarm sound repeats until the user reacts.
        additionalFlags: isJamah ? Int32List.fromList(<int>[4]) : null,
        styleInformation: BigTextStyleInformation(body),
        actions: actions,
      ),
    );
  }

  /// Schedules the next [daysAhead] days. Safe to call again and again:
  /// the same id replaces the old notification.
  Future<void> rescheduleAll({
    required SharedPreferences prefs,
    DayLog Function(DateTime day)? logFor,
    int daysAhead = 3,
    bool includeToday = true,
  }) async {
    final jamah = SettingsStore.loadJamah(prefs);
    final sm = await _scheduleMode();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var d = includeToday ? 0 : 1; d <= daysAhead; d++) {
      final day = today.add(Duration(days: d));
      final mode = SettingsStore.modeFor(day, prefs);
      final log = d == 0 ? logFor?.call(day) : null;

      for (final s in ReminderSlot.build(jamah, mode)) {
        final done = log != null && s.isDone(log, mode);
        for (var a = 0; a < s.attempts; a++) {
          final id = notifId(day, s.type, s.slot, a);
          if (done) {
            await _plugin.cancel(id);
            continue;
          }
          final when = s.timeFor(day, a);
          if (!when.isAfter(now)) continue;
          final body = s.bodyFor(a);
          await _plugin.zonedSchedule(
            id,
            s.title,
            body,
            tz.TZDateTime.from(when, tz.local),
            _details(s, body),
            androidScheduleMode: sm,
            payload: s.payload(day),
          );
        }
      }
    }
  }

  /// Stops the nagging chain (and snoozes) of one reminder for one day.
  Future<void> cancelSlot(DateTime day, HabitType type, int slot) async {
    for (var a = 0; a < 10; a++) {
      await _plugin.cancel(notifId(day, type, slot, a));
    }
  }

  Future<void> _snooze(DateTime day, HabitType type, int slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final mode = SettingsStore.modeFor(day, prefs);
    final matches = ReminderSlot.build(SettingsStore.loadJamah(prefs), mode)
        .where((s) => s.type == type && s.slot == slot);
    if (matches.isEmpty) return;
    final s = matches.first;
    final sm = await _scheduleMode();
    final now = DateTime.now();
    // Snooze: alert after 10 min, then nag at +15 and +20 if still not done.
    for (var i = 0; i < 3; i++) {
      final when = now.add(Duration(minutes: 10 + 5 * i));
      final body = s.bodyFor(1);
      await _plugin.zonedSchedule(
        notifId(day, type, slot, 5 + i),
        s.title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details(s, body),
        androidScheduleMode: sm,
        payload: s.payload(day),
      );
    }
  }

  /// Runs in a background isolate when [Done] (no UI) or [Snooze 10m] is tapped.
  static Future<void> handleBackgroundResponse(
      NotificationResponse r) async {
    DartPluginRegistrant.ensureInitialized();
    final payload = r.payload;
    if (payload == null) return;
    final p = payload.split('|');
    if (p.length < 3) return;
    final type = HabitType.values[int.parse(p[0])];
    final slot = int.parse(p[1]);
    final day = parseDateKey(p[2]);

    final svc = NotificationService.instance;
    await svc.init(background: true);

    if (r.actionId == 'done') {
      await svc.cancelSlot(day, type, slot);
      final prefs = await SharedPreferences.getInstance();
      await SettingsStore.addPending(prefs, payload);
    } else if (r.actionId == 'snooze') {
      await svc.cancelSlot(day, type, slot);
      await svc._snooze(day, type, slot);
    }
  }
}
