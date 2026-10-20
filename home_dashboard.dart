import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../models/lifestyle_model.dart';
import '../models/prayer_model.dart';
import '../widgets/common.dart';

const List<int> _weekdayOrder = [7, 1, 2, 3, 4, 5, 6];
const Map<int, String> _weekdayShort = {
  7: 'রবি',
  1: 'সোম',
  2: 'মঙ্গল',
  3: 'বুধ',
  4: 'বৃহ',
  5: 'শুক্র',
  6: 'শনি',
};
const List<String> _weekdayFull = [
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
  'রবিবার',
];

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Header(c),
          _ModeCard(c),
          _NextJamahCard(c),
          _PrayerCard(c),
          _WaterCard(c),
          _SunlightCard(c),
          _ChecklistCard(c),
          _SetupCard(c),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.c);
  final AppController c;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final score = computeScore(c.log, c.mode).total;
    final color = score >= 80 ? kAccent : (score >= 50 ? kWarn : kBad);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Istiqamah',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${_weekdayFull[now.weekday - 1]}, ${toBn(now.day)}/${toBn(now.month)}/${toBn(now.year)}',
                  style: const TextStyle(color: kMuted),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
            ),
            child: Text(toBn(score),
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard(this.c);
  final AppController c;

  @override
  Widget build(BuildContext context) {
    final workCount = c.workDays.length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('${toBn(workCount)} + ${toBn(7 - workCount)} সময়সূচি',
              icon: Icons.calendar_month),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<DayMode>(
              segments: const [
                ButtonSegment(
                    value: DayMode.work,
                    label: Text('কর্মদিবস'),
                    icon: Icon(Icons.work_outline)),
                ButtonSegment(
                    value: DayMode.rest,
                    label: Text('বিশ্রাম/ইবাদাত'),
                    icon: Icon(Icons.self_improvement)),
              ],
              selected: {c.mode},
              onSelectionChanged: (s) => c.setTodayMode(s.first),
            ),
          ),
          const SizedBox(height: 12),
          const Text('কোন দিনগুলো কাজের? (নির্বাচিত = কাজের দিন)',
              style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final d in _weekdayOrder)
                FilterChip(
                  label: Text(_weekdayShort[d]!),
                  selected: c.workDays.contains(d),
                  onSelected: (_) => c.toggleWorkDay(d),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextJamahCard extends StatelessWidget {
  const _NextJamahCard(this.c);
  final AppController c;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: TickBuilder(
        builder: (_) {
          final n = c.nextJamah();
          final left = n.time.difference(DateTime.now());
          final t = c.jamah[n.kind]!;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('পরবর্তী জামাত',
                        style: TextStyle(color: kMuted)),
                    const SizedBox(height: 4),
                    Text('${n.kind.bn} • ${t.label}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Text(fmtDuration(left),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kAccent,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          );
        },
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard(this.c);
  final AppController c;

  Future<void> _pickTime(BuildContext context, PrayerKind k) async {
    final cur = c.jamah[k]!;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur.hour, minute: cur.minute),
    );
    if (t != null) await c.setJamah(k, JamahTime(t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('পাঁচ ওয়াক্ত নামাজ', icon: Icons.mosque),
          for (final k in PrayerKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(k.bn,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _pickTime(context, k),
                        icon: const Icon(Icons.alarm, size: 18),
                        label: Text('জামাত ${c.jamah[k]!.label}'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in const [
                        PrayerStatus.jamah,
                        PrayerStatus.alone,
                        PrayerStatus.missed
                      ])
                        ChoiceChip(
                          label: Text(s.bn),
                          selected: c.log.statusOf(k) == s,
                          onSelected: (_) => c.setPrayerStatus(k, s),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard(this.c);
  final AppController c;

  @override
  Widget build(BuildContext context) {
    final g = c.log.waterGlasses;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('পানি পান', icon: Icons.water_drop),
          Row(
            children: [
              Text('${toBn(g)}/${toBn(Targets.waterGlasses)} গ্লাস',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                onPressed: () => c.addWater(-1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              FilledButton.icon(
                onPressed: () => c.addWater(1),
                icon: const Icon(Icons.add),
                label: const Text('+1 Glass'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (g / Targets.waterGlasses).clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

class _SunlightCard extends StatelessWidget {
  const _SunlightCard(this.c);
  final AppController c;

  @override
  Widget build(BuildContext context) {
    final target = Targets.outdoorMinutes(c.mode);
    return Panel(
      child: TickBuilder(
        builder: (_) {
          final secs = c.sunlightSeconds;
          final ratio = (secs / (target * 60)).clamp(0.0, 1.0).toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('রোদ ও খোলা বাতাস', icon: Icons.wb_sunny),
              Row(
                children: [
                  Text(fmtDuration(Duration(seconds: secs)),
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: c.toggleSunlight,
                    icon: Icon(
                        c.sunlightRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(c.sunlightRunning ? 'থামাও' : 'শুরু'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('লক্ষ্য: কমপক্ষে ${toBn(target)} মিনিট',
                  style: const TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard(this.c);
  final AppController c;

  Widget _row(bool done, String label, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? kAccent : kMuted, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _minutes(WorkField f, int step) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => c.addMinutes(f, -step),
            icon: const Icon(Icons.remove_circle_outline, size: 20)),
        IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => c.addMinutes(f, step),
            icon: const Icon(Icons.add_circle_outline, size: 20)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = c.log;
    final prayed = PrayerKind.values
        .where((k) => l.statusOf(k) != PrayerStatus.none)
        .length;
    final outTarget = Targets.outdoorMinutes(c.mode);
    final work = c.mode == DayMode.work;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(work ? 'আজকের তালিকা (কর্মদিবস)' : 'আজকের তালিকা (বিশ্রামের দিন)',
              icon: Icons.checklist),
          _row(prayed == 5, 'নামাজের হিসাব ${toBn(prayed)}/৫'),
          _row(l.waterGlasses >= Targets.waterGlasses,
              'পানি ${toBn(l.waterGlasses)}/${toBn(Targets.waterGlasses)}'),
          _row(l.outdoorSeconds >= outTarget * 60,
              'রোদ ${toBn(l.outdoorSeconds ~/ 60)}/${toBn(outTarget)} মিনিট'),
          _row(l.allZikrsDone, 'তাসবিহ ${toBn(l.completedZikrs)}/৪'),
          _row(l.morningDua, 'সকালের দুআ'),
          _row(l.eveningDua, 'সন্ধ্যার দুআ'),
          if (work) ...[
            _row(l.englishMinutes >= Targets.englishMinutes,
                'ইংলিশ প্র্যাক্টিস ${toBn(l.englishMinutes)}/${toBn(Targets.englishMinutes)} মি.',
                trailing: _minutes(WorkField.english, 10)),
            _row(l.aiMinutes >= Targets.aiMinutes,
                'এআই টুলস/ওয়ার্কফ্লো ${toBn(l.aiMinutes)}/${toBn(Targets.aiMinutes)} মি.',
                trailing: _minutes(WorkField.ai, 15)),
          ] else ...[
            _row(l.quranMinutes >= Targets.quranMinutes,
                'কুরআন তিলাওয়াত ${toBn(l.quranMinutes)}/${toBn(Targets.quranMinutes)} মি.',
                trailing: _minutes(WorkField.quran, 10)),
            _row(l.familyMinutes >= Targets.familyMinutes,
                'পরিবারের সময় ${toBn(l.familyMinutes)}/${toBn(Targets.familyMinutes)} মি.',
                trailing: _minutes(WorkField.family, 15)),
          ],
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard(this.c);
  final AppController c;

  Future<void> _batteryGuide(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ব্যাটারি অপ্টিমাইজেশন বন্ধ করো'),
        content: const Text(
            'অনেক ফোন ব্যাকগ্রাউন্ড অ্যাপ বন্ধ করে দেয়, তখন এলার্ম বাজে না।\n\n'
            '১. নিচের বাটনে চাপ দিয়ে সেটিংস খোলো।\n'
            '২. Istiqamah খুঁজে "Don\'t optimize" / "Unrestricted" দাও।\n'
            '৩. Xiaomi, Oppo, Vivo, Realme, Samsung ফোনে App info > Battery এও "No restrictions" দাও এবং Autostart চালু করো।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('বাতিল')),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              const intent = AndroidIntent(
                  action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS');
              await intent.launch();
            },
            child: const Text('সেটিংস খোলো'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('এলার্ম সেটআপ', icon: Icons.notifications_active),
          const Text(
              'এলার্ম ঠিকমতো বাজাতে নোটিফিকেশন ও Exact Alarm পারমিশন দিতে হবে, আর ব্যাটারি অপ্টিমাইজেশন বন্ধ রাখতে হবে।',
              style: TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                  onPressed: c.requestPermissions,
                  child: const Text('পারমিশন দাও')),
              OutlinedButton(
                  onPressed: () => _batteryGuide(context),
                  child: const Text('ব্যাটারি সেটিংস')),
            ],
          ),
        ],
      ),
    );
  }
}
