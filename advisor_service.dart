import '../models/lifestyle_model.dart';
import '../models/prayer_model.dart';

enum AdviceTone { good, warn, bad }

class AdviceCard {
  const AdviceCard(this.title, this.message, this.tone);

  final String title;
  final String message;
  final AdviceTone tone;
}

/// Rule-based Bangla lifestyle advisor. No internet or AI model needed.
class AdvisorService {
  static List<AdviceCard> evaluate(DayLog log, DayMode mode) {
    final cards = <AdviceCard>[];

    // --- Sunlight ---
    final outMin = log.outdoorSeconds ~/ 60;
    final outTarget = Targets.outdoorMinutes(mode);
    if (outMin < 10) {
      cards.add(const AdviceCard(
          'রোদ ও খোলা বাতাস',
          'আজ তুমি রোদে যাওনি। ঘরে শুয়ে থাকার কারণে শরীরে অলসতা বেড়েছে। কাল ফজরের পর অন্তত ১৫ মিনিট বাইরে যাও।',
          AdviceTone.bad));
    } else if (outMin < outTarget) {
      cards.add(AdviceCard(
          'রোদ ও খোলা বাতাস',
          'বাইরে ${toBn(outMin)} মিনিট কাটিয়েছো, লক্ষ্য ${toBn(outTarget)} মিনিট। আরও ${toBn(outTarget - outMin)} মিনিট হাঁটলেই লক্ষ্য পূরণ হবে।',
          AdviceTone.warn));
    } else {
      cards.add(AdviceCard(
          'রোদ ও খোলা বাতাস',
          'চমৎকার! আজ ${toBn(outMin)} মিনিট খোলা বাতাসে কাটিয়েছো। এই অভ্যাস ধরে রাখো।',
          AdviceTone.good));
    }

    // --- Water ---
    final w = log.waterGlasses;
    if (w < 4) {
      cards.add(const AdviceCard(
          'পানি',
          'পানির ঘাটতির কারণে মাথায় ক্লান্তি আসছে। এখনই এক গ্লাস পানি খাও।',
          AdviceTone.bad));
    } else if (w < Targets.waterGlasses) {
      cards.add(AdviceCard(
          'পানি',
          'আজ ${toBn(w)} গ্লাস হয়েছে, লক্ষ্য ${toBn(Targets.waterGlasses)} গ্লাস। ঘুমানোর আগে বাকিটা শেষ করো।',
          AdviceTone.warn));
    } else {
      cards.add(const AdviceCard(
          'পানি', 'পানির লক্ষ্য পূরণ হয়েছে। চালিয়ে যাও।', AdviceTone.good));
    }

    // --- Prayers ---
    final missed = log.countOf(PrayerStatus.missed);
    final jamah = log.countOf(PrayerStatus.jamah);
    final alone = log.countOf(PrayerStatus.alone);
    final unmarked = log.countOf(PrayerStatus.none);
    if (missed > 0) {
      cards.add(AdviceCard(
          'নামাজ',
          'আজ ${toBn(missed)} ওয়াক্ত নামাজ কাযা হয়েছে। কাযা আদায় করে নাও। কাল প্রতিটি জামাতের ১০ মিনিট আগে ওযু সেরে বসে থাকো।',
          AdviceTone.bad));
    } else if (jamah == 5) {
      cards.add(const AdviceCard('নামাজ',
          'পাঁচ ওয়াক্তই জামাতে পড়েছো। আলহামদুলিল্লাহ, এটাই ইস্তিকামাহ।',
          AdviceTone.good));
    } else if (alone > 0) {
      cards.add(AdviceCard(
          'নামাজ',
          'আজ ${toBn(jamah)} ওয়াক্ত জামাতে আর ${toBn(alone)} ওয়াক্ত একা পড়েছো। জামাতের জন্য আরও আগে প্রস্তুতি নাও।',
          AdviceTone.warn));
    } else if (unmarked > 0 && jamah > 0) {
      cards.add(AdviceCard(
          'নামাজ',
          '${toBn(unmarked)} ওয়াক্তের হিসাব এখনো দেওয়া হয়নি। সৎভাবে মার্ক করো।',
          AdviceTone.warn));
    }

    // --- Tasbih ---
    final z = log.completedZikrs;
    if (z == 4) {
      cards.add(const AdviceCard(
          'তাসবিহ', 'আজকের চারটি জিকিরই ১০০ বার করে সম্পন্ন।', AdviceTone.good));
    } else {
      cards.add(AdviceCard(
          'তাসবিহ',
          'চারটির মধ্যে ${toBn(z)}টি জিকির সম্পন্ন হয়েছে। ফোনে স্ক্রল না করে বাকিগুলো এখনই শেষ করো।',
          z == 0 ? AdviceTone.bad : AdviceTone.warn));
    }

    // --- Work / rest specific ---
    if (mode == DayMode.work) {
      if (log.englishMinutes < Targets.englishMinutes) {
        cards.add(AdviceCard(
            'ইংলিশ প্র্যাক্টিস',
            'ইংলিশ প্র্যাক্টিস ${toBn(log.englishMinutes)}/${toBn(Targets.englishMinutes)} মিনিট। বিছানায় না, টেবিলে বসে ৩০ মিনিট করো।',
            AdviceTone.warn));
      }
      if (log.aiMinutes < Targets.aiMinutes) {
        cards.add(AdviceCard(
            'এআই ওয়ার্কফ্লো',
            'এআই টুলসের কাজ ${toBn(log.aiMinutes)}/${toBn(Targets.aiMinutes)} মিনিট। একটা ছোট কাজ ঠিক করে ৬০ মিনিটের টাইমার ধরো।',
            AdviceTone.warn));
      }
    } else {
      if (log.familyMinutes < 60) {
        cards.add(const AdviceCard(
            'পরিবার',
            'ছুটির দিনেও পরিবারকে সময় দেওয়া হয়নি। আজ অন্তত এক ঘণ্টা ফোন রেখে সবার সাথে কাটাও।',
            AdviceTone.bad));
      }
      if (log.quranMinutes < Targets.quranMinutes) {
        cards.add(const AdviceCard(
            'কুরআন তিলাওয়াত',
            'ছুটির দিনে ইবাদত বাড়ানোর কথা ছিল। আজ ৩০ মিনিট কুরআন তিলাওয়াত করো।',
            AdviceTone.warn));
      }
    }

    // --- Overall ---
    final score = computeScore(log, mode).total;
    if (score >= 80) {
      cards.insert(
          0,
          AdviceCard('আজকের মূল্যায়ন',
              'আজকের স্কোর ${toBn(score)}/১০০। দারুণ শৃঙ্খলা! কাল একই মান ধরে রাখো।',
              AdviceTone.good));
    } else if (score >= 50) {
      cards.insert(
          0,
          AdviceCard('আজকের মূল্যায়ন',
              'আজকের স্কোর ${toBn(score)}/১০০। মাঝামাঝি। নিচের লাল কার্ডগুলো আগে ঠিক করো।',
              AdviceTone.warn));
    } else {
      cards.insert(
          0,
          AdviceCard('আজকের মূল্যায়ন',
              'আজকের স্কোর ${toBn(score)}/১০০। সত্যি বলতে আজ অনেক পিছিয়ে আছো। এখনই উঠে দাঁড়াও, এক গ্লাস পানি খাও, তারপর ছোট একটা কাজ শুরু করো।',
              AdviceTone.bad));
    }
    return cards;
  }
}
