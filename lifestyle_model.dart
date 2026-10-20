import 'prayer_model.dart';
import 'tasbih_model.dart';

enum DayMode { work, rest }

enum HabitType { jamah, water, sunlight, tasbih, stand }

String two(int n) => n.toString().padLeft(2, '0');

String dateKeyOf(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime parseDateKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Days since 2020-01-01. Used to build stable notification ids.
int dayIndexOf(DateTime d) => DateTime.utc(d.year, d.month, d.day)
    .difference(DateTime.utc(2020, 1, 1))
    .inDays;

String toBn(Object value) {
  const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return value
      .toString()
      .split('')
      .map((c) {
        final i = int.tryParse(c);
        return i == null ? c : digits[i];
      })
      .join();
}

class Targets {
  static int outdoorMinutes(DayMode m) => m == DayMode.rest ? 60 : 20;
  static const int waterGlasses = 8;
  static const int englishMinutes = 30;
  static const int aiMinutes = 60;
  static const int familyMinutes = 120;
  static const int quranMinutes = 30;
}

class DayLog {
  DayLog({
    required this.dateKey,
    Map<String, int>? prayers,
    Map<String, int>? tasbih,
    this.waterGlasses = 0,
    this.outdoorSeconds = 0,
    this.englishMinutes = 0,
    this.aiMinutes = 0,
    this.familyMinutes = 0,
    this.quranMinutes = 0,
    this.morningDua = false,
    this.eveningDua = false,
  })  : prayers = prayers ?? <String, int>{},
        tasbih = tasbih ?? <String, int>{};

  final String dateKey;
  final Map<String, int> prayers; // PrayerKind.name -> PrayerStatus.index
  final Map<String, int> tasbih; // zikr id -> count
  int waterGlasses;
  int outdoorSeconds;
  int englishMinutes;
  int aiMinutes;
  int familyMinutes;
  int quranMinutes;
  bool morningDua;
  bool eveningDua;

  PrayerStatus statusOf(PrayerKind k) {
    final i = prayers[k.name];
    if (i == null || i < 0 || i >= PrayerStatus.values.length) {
      return PrayerStatus.none;
    }
    return PrayerStatus.values[i];
  }

  int countOf(PrayerStatus s) =>
      PrayerKind.values.where((k) => statusOf(k) == s).length;

  int tasbihCount(String id) => tasbih[id] ?? 0;

  int get completedZikrs =>
      zikrList.where((z) => tasbihCount(z.id) >= z.target).length;

  bool get allZikrsDone => completedZikrs == zikrList.length;

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'prayers': prayers,
        'tasbih': tasbih,
        'water': waterGlasses,
        'outdoor': outdoorSeconds,
        'english': englishMinutes,
        'ai': aiMinutes,
        'family': familyMinutes,
        'quran': quranMinutes,
        'morningDua': morningDua,
        'eveningDua': eveningDua,
      };

  factory DayLog.fromMap(Map m) {
    Map<String, int> intMap(dynamic v) {
      final out = <String, int>{};
      if (v is Map) {
        v.forEach((k, val) => out[k.toString()] = (val as num).toInt());
      }
      return out;
    }

    int n(String k) => (m[k] as num?)?.toInt() ?? 0;

    return DayLog(
      dateKey: (m['dateKey'] ?? '') as String,
      prayers: intMap(m['prayers']),
      tasbih: intMap(m['tasbih']),
      waterGlasses: n('water'),
      outdoorSeconds: n('outdoor'),
      englishMinutes: n('english'),
      aiMinutes: n('ai'),
      familyMinutes: n('family'),
      quranMinutes: n('quran'),
      morningDua: m['morningDua'] == true,
      eveningDua: m['eveningDua'] == true,
    );
  }
}

class ScoreItem {
  const ScoreItem(this.label, this.earned, this.max);

  final String label;
  final double earned;
  final double max;

  double get ratio => max <= 0 ? 0 : (earned / max).clamp(0.0, 1.0).toDouble();
}

class DailyScore {
  const DailyScore(this.items);

  final List<ScoreItem> items;

  int get total => items.fold<double>(0, (s, i) => s + i.earned).round();
}

DailyScore computeScore(DayLog log, DayMode mode) {
  double ratio(num v, num t) =>
      t <= 0 ? 1.0 : (v / t).clamp(0.0, 1.0).toDouble();

  var prayerPts = 0.0;
  for (final k in PrayerKind.values) {
    switch (log.statusOf(k)) {
      case PrayerStatus.jamah:
        prayerPts += 8;
        break;
      case PrayerStatus.alone:
        prayerPts += 5;
        break;
      default:
        break;
    }
  }

  final tasbihRatio = zikrList.fold<double>(
          0, (s, z) => s + ratio(log.tasbihCount(z.id), z.target)) /
      zikrList.length;

  final items = <ScoreItem>[
    ScoreItem('নামাজ', prayerPts, 40),
    ScoreItem(
        'পানি', ratio(log.waterGlasses, Targets.waterGlasses) * 15, 15),
    ScoreItem(
        'রোদ ও খোলা বাতাস',
        ratio(log.outdoorSeconds / 60, Targets.outdoorMinutes(mode)) * 15,
        15),
    ScoreItem('তাসবিহ', tasbihRatio * 15, 15),
  ];

  if (mode == DayMode.work) {
    items.add(ScoreItem('ইংলিশ প্র্যাক্টিস',
        ratio(log.englishMinutes, Targets.englishMinutes) * 7.5, 7.5));
    items.add(ScoreItem('এআই ওয়ার্কফ্লো',
        ratio(log.aiMinutes, Targets.aiMinutes) * 7.5, 7.5));
  } else {
    items.add(ScoreItem('পরিবারের সময়',
        ratio(log.familyMinutes, Targets.familyMinutes) * 7.5, 7.5));
    items.add(ScoreItem('কুরআন তিলাওয়াত',
        ratio(log.quranMinutes, Targets.quranMinutes) * 7.5, 7.5));
  }
  return DailyScore(items);
}
