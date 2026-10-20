class Zikr {
  const Zikr({
    required this.id,
    required this.title,
    required this.arabic,
    required this.bangla,
    this.target = 100,
  });

  final String id;
  final String title;
  final String arabic;
  final String bangla;
  final int target;
}

const List<Zikr> zikrList = [
  Zikr(
    id: 'darood',
    title: 'দরূদে ইবরাহীম',
    arabic:
        'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
    bangla:
        'আল্লাহুম্মা সাল্লি আলা মুহাম্মাদিউ ওয়া আলা আলি মুহাম্মাদিন, কামা সাল্লাইতা আলা ইবরাহীমা ওয়া আলা আলি ইবরাহীমা, ইন্নাকা হামীদুম মাজীদ।',
  ),
  Zikr(
    id: 'astaghfirullah',
    title: 'আস্তাগফিরুল্লাহ',
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    bangla: 'আস্তাগফিরুল্লাহ',
  ),
  Zikr(
    id: 'jalali',
    title: 'ইয়া যাল জালালি ওয়াল ইকরাম',
    arabic: 'يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    bangla: 'ইয়া যাল জালালি ওয়াল ইকরাম',
  ),
  Zikr(
    id: 'yunus',
    title: 'লা ইলাহা ইল্লা আন্তা...',
    arabic:
        'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    bangla:
        'লা ইলাহা ইল্লা আনতা সুবহানাকা ইন্নী কুনতু মিনায যালিমীন।',
  ),
];
