enum PrayerKind { fajr, dhuhr, asr, maghrib, isha }

extension PrayerKindX on PrayerKind {
  String get bn {
    switch (this) {
      case PrayerKind.fajr:
        return 'ফজর';
      case PrayerKind.dhuhr:
        return 'যোহর';
      case PrayerKind.asr:
        return 'আসর';
      case PrayerKind.maghrib:
        return 'মাগরিব';
      case PrayerKind.isha:
        return 'ইশা';
    }
  }
}

enum PrayerStatus { none, jamah, alone, missed }

extension PrayerStatusX on PrayerStatus {
  String get bn {
    switch (this) {
      case PrayerStatus.none:
        return '—';
      case PrayerStatus.jamah:
        return 'জামাতে';
      case PrayerStatus.alone:
        return 'একা';
      case PrayerStatus.missed:
        return 'কাযা';
    }
  }
}

class JamahTime {
  const JamahTime(this.hour, this.minute);

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  String encode() => '$hour:$minute';

  static JamahTime parse(String s) {
    final p = s.split(':');
    return JamahTime(int.parse(p[0]), int.parse(p[1]));
  }

  String get label {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h12:$m ${hour < 12 ? 'AM' : 'PM'}';
  }
}

/// Starting values. The user can change every time on the dashboard.
const Map<PrayerKind, JamahTime> defaultJamah = {
  PrayerKind.fajr: JamahTime(5, 0),
  PrayerKind.dhuhr: JamahTime(12, 15),
  PrayerKind.asr: JamahTime(15, 30),
  PrayerKind.maghrib: JamahTime(17, 30),
  PrayerKind.isha: JamahTime(19, 0),
};

class PrayerModel {
  const PrayerModel(this.kind, this.jamah);

  final PrayerKind kind;
  final JamahTime jamah;
}
