import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../widgets/common.dart';

class Dua {
  const Dua({
    required this.title,
    required this.arabic,
    required this.pronunciation,
    required this.meaning,
    this.note,
  });

  final String title;
  final String arabic;
  final String pronunciation;
  final String meaning;
  final String? note;
}

const Dua _sayyidulIstighfar = Dua(
  title: 'সাইয়্যিদুল ইস্তিগফার',
  arabic:
      'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
  pronunciation:
      'আল্লাহুম্মা আনতা রাব্বী, লা ইলাহা ইল্লা আনতা, খালাক্বতানী ওয়া আনা আবদুকা, ওয়া আনা আলা আহদিকা ওয়া ওয়া\'দিকা মাসতাতা\'তু, আউযু বিকা মিন শাররি মা সানা\'তু, আবূউ লাকা বিনি\'মাতিকা আলাইয়া, ওয়া আবূউ বিযামবী, ফাগফির লী, ফাইন্নাহু লা ইয়াগফিরুয যুনূবা ইল্লা আনতা।',
  meaning:
      'হে আল্লাহ! আপনি আমার রব। আপনি ছাড়া কোনো ইলাহ নেই। আপনি আমাকে সৃষ্টি করেছেন, আমি আপনার বান্দা। আমি যথাসাধ্য আপনার অঙ্গীকার ও প্রতিশ্রুতির ওপর আছি। আমি যা করেছি তার অনিষ্ট থেকে আপনার আশ্রয় চাই। আমার ওপর আপনার নিয়ামত স্বীকার করছি এবং আমার গুনাহও স্বীকার করছি। তাই আমাকে ক্ষমা করুন, কারণ আপনি ছাড়া কেউ গুনাহ ক্ষমা করতে পারে না।',
);

const Dua _bismillahProtection = Dua(
  title: 'সকাল-সন্ধ্যার সুরক্ষার দুআ',
  arabic:
      'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
  pronunciation:
      'বিসমিল্লাহিল্লাযী লা ইয়াদুররু মা\'আসমিহী শাইউন ফিল আরদ্বি ওয়ালা ফিস সামাই, ওয়া হুয়াস সামীউল আলীম।',
  meaning:
      'আল্লাহর নামে, যাঁর নামের সাথে আসমান ও জমিনের কোনো কিছুই ক্ষতি করতে পারে না। তিনি সর্বশ্রোতা, সর্বজ্ঞ।',
  note: 'তিনবার পড়ো',
);

const List<Dua> morningDuas = [
  Dua(
    title: 'সকালের শুরুর দুআ',
    arabic:
        'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    pronunciation:
        'আসবাহনা ওয়া আসবাহাল মুলকু লিল্লাহি, ওয়াল হামদু লিল্লাহি, লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু লা শারীকা লাহু।',
    meaning:
        'আমরা সকালে উপনীত হলাম এবং সমস্ত রাজত্ব সকালে উপনীত হলো আল্লাহর জন্য। সমস্ত প্রশংসা আল্লাহর। আল্লাহ ছাড়া কোনো ইলাহ নেই, তিনি একক, তাঁর কোনো শরীক নেই।',
  ),
  Dua(
    title: 'সকালের দুআ (বিকা আসবাহনা)',
    arabic:
        'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
    pronunciation:
        'আল্লাহুম্মা বিকা আসবাহনা, ওয়া বিকা আমসাইনা, ওয়া বিকা নাহইয়া, ওয়া বিকা নামূতু, ওয়া ইলাইকান নুশূর।',
    meaning:
        'হে আল্লাহ! আপনার অনুগ্রহেই আমরা সকাল করলাম, আপনার অনুগ্রহেই সন্ধ্যা করি, আপনার ইচ্ছায় বাঁচি ও মরি, আর আপনার কাছেই পুনরুত্থান।',
  ),
  _sayyidulIstighfar,
  _bismillahProtection,
];

const List<Dua> eveningDuas = [
  Dua(
    title: 'সন্ধ্যার শুরুর দুআ',
    arabic:
        'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    pronunciation:
        'আমসাইনা ওয়া আমসাল মুলকু লিল্লাহি, ওয়াল হামদু লিল্লাহি, লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু লা শারীকা লাহু।',
    meaning:
        'আমরা সন্ধ্যায় উপনীত হলাম এবং সমস্ত রাজত্ব সন্ধ্যায় উপনীত হলো আল্লাহর জন্য। সমস্ত প্রশংসা আল্লাহর। আল্লাহ ছাড়া কোনো ইলাহ নেই, তিনি একক, তাঁর কোনো শরীক নেই।',
  ),
  Dua(
    title: 'সন্ধ্যার দুআ (বিকা আমসাইনা)',
    arabic:
        'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
    pronunciation:
        'আল্লাহুম্মা বিকা আমসাইনা, ওয়া বিকা আসবাহনা, ওয়া বিকা নাহইয়া, ওয়া বিকা নামূতু, ওয়া ইলাইকাল মাসীর।',
    meaning:
        'হে আল্লাহ! আপনার অনুগ্রহেই আমরা সন্ধ্যা করলাম, আপনার অনুগ্রহেই সকাল করি, আপনার ইচ্ছায় বাঁচি ও মরি, আর আপনার কাছেই প্রত্যাবর্তন।',
  ),
  Dua(
    title: 'অনিষ্ট থেকে আশ্রয়',
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    pronunciation:
        'আউযু বিকালিমাতিল্লাহিত তাম্মাতি মিন শাররি মা খালাক্ব।',
    meaning:
        'আমি আল্লাহর পরিপূর্ণ কালেমাসমূহের আশ্রয় চাই তাঁর সৃষ্ট সবকিছুর অনিষ্ট থেকে।',
    note: 'তিনবার পড়ো',
  ),
  _sayyidulIstighfar,
  _bismillahProtection,
];

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: const [
            TabBar(
              tabs: [
                Tab(text: 'সকালের দুআ'),
                Tab(text: 'সন্ধ্যার দুআ'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DuaList(duas: morningDuas, morning: true),
                  _DuaList(duas: eveningDuas, morning: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuaList extends StatelessWidget {
  const _DuaList({required this.duas, required this.morning});

  final List<Dua> duas;
  final bool morning;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final read = morning ? c.log.morningDua : c.log.eveningDua;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final d in duas) _DuaCard(dua: d),
        FilledButton.icon(
          onPressed: () => c.setDuaRead(morning: morning, value: !read),
          icon: Icon(read ? Icons.check_circle : Icons.check_circle_outline),
          label: Text(read ? 'পড়া হয়েছে (চাপলে বাতিল)' : 'পড়া হয়েছে'),
        ),
      ],
    );
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.dua});

  final Dua dua;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(dua.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kAccent)),
              ),
              if (dua.note != null)
                Text(dua.note!,
                    style: const TextStyle(color: kWarn, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(dua.arabic,
                  style: const TextStyle(fontSize: 24, height: 2.0)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('উচ্চারণ',
              style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(dua.pronunciation, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 10),
          const Text('অর্থ', style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(dua.meaning, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
