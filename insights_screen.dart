import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../models/lifestyle_model.dart';
import '../services/advisor_service.dart';
import '../widgets/common.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  Color _toneColor(AdviceTone t) {
    switch (t) {
      case AdviceTone.good:
        return kAccent;
      case AdviceTone.warn:
        return kWarn;
      case AdviceTone.bad:
        return kBad;
    }
  }

  IconData _toneIcon(AdviceTone t) {
    switch (t) {
      case AdviceTone.good:
        return Icons.thumb_up_alt_outlined;
      case AdviceTone.warn:
        return Icons.info_outline;
      case AdviceTone.bad:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final score = c.score;
    final total = score.total;
    final ringColor = total >= 80 ? kAccent : (total >= 50 ? kWarn : kBad);
    final history = c.history();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('আজকের হিসাব',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: total / 100,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: kPanelBorder,
                        color: ringColor,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(toBn(total),
                                style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    color: ringColor)),
                            const Text('/ ১০০',
                                style: TextStyle(color: kMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final i in score.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 120,
                            child: Text(i.label,
                                style: const TextStyle(fontSize: 13))),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: i.ratio,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 52,
                          child: Text(
                              '${toBn(i.earned.round())}/${toBn(i.max.round())}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  color: kMuted, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('শেষ ৭ দিন', icon: Icons.show_chart),
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final e in history)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(toBn(e.value),
                                  style: const TextStyle(
                                      fontSize: 11, color: kMuted)),
                              const SizedBox(height: 3),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                height: 4 + (e.value / 100) * 70,
                                decoration: BoxDecoration(
                                  color: e.value >= 80
                                      ? kAccent
                                      : (e.value >= 50 ? kWarn : kBad),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(DateFormat('d/M').format(e.key),
                                  style: const TextStyle(
                                      fontSize: 10, color: kMuted)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('উপদেষ্টার মতামত', icon: Icons.psychology_alt),
          for (final a in c.advice)
            Panel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_toneIcon(a.tone), color: _toneColor(a.tone)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _toneColor(a.tone))),
                        const SizedBox(height: 4),
                        Text(a.message, style: const TextStyle(height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
