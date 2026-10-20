import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../models/lifestyle_model.dart';
import '../models/tasbih_model.dart';
import '../widgets/common.dart';

/// List of the 4 daily zikrs. Tap one to open the full-screen counter.
class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('ডিজিটাল তাসবিহ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('আজ ${toBn(c.log.completedZikrs)}/৪ জিকির সম্পন্ন',
              style: const TextStyle(color: kMuted)),
          const SizedBox(height: 16),
          for (var i = 0; i < zikrList.length; i++)
            _ZikrTile(index: i, count: c.log.tasbihCount(zikrList[i].id)),
        ],
      ),
    );
  }
}

class _ZikrTile extends StatelessWidget {
  const _ZikrTile({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final z = zikrList[index];
    final done = count >= z.target;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => TasbihCounterPage(index: index)),
      ),
      child: Panel(
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: (count / z.target).clamp(0.0, 1.0).toDouble(),
                    strokeWidth: 5,
                    backgroundColor: kPanelBorder,
                  ),
                  Center(
                    child: done
                        ? const Icon(Icons.check, color: kAccent)
                        : Text(toBn(count),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(z.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${toBn(count)}/${toBn(z.target)}',
                      style: const TextStyle(color: kMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    );
  }
}

/// Full-screen tap counter: haptics, click sound, circular progress, auto-save at 100.
class TasbihCounterPage extends StatefulWidget {
  const TasbihCounterPage({super.key, required this.index});

  final int index;

  @override
  State<TasbihCounterPage> createState() => _TasbihCounterPageState();
}

class _TasbihCounterPageState extends State<TasbihCounterPage> {
  double _scale = 1.0;

  Zikr get _zikr => zikrList[widget.index];

  Future<void> _tap() async {
    setState(() => _scale = 0.93);
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _scale = 1.0);
    });
    await context.read<AppController>().tapTasbih(_zikr);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final z = _zikr;
    final count = c.log.tasbihCount(z.id);
    final done = count >= z.target;
    final hasNext = widget.index < zikrList.length - 1;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: done ? null : _tap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close)),
                    Expanded(
                      child: Text(z.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                        tooltip: 'রিসেট',
                        onPressed: () => c.resetTasbih(z),
                        icon: const Icon(Icons.restart_alt)),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 130),
                  child: SingleChildScrollView(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(z.arabic,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, height: 1.9)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(z.bangla,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 13)),
                const Spacer(),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                            begin: 0, end: (count / z.target).clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 200),
                        builder: (context, v, _) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          backgroundColor: kPanelBorder,
                          color: done ? kAccent : null,
                        ),
                      ),
                      Center(
                        child: AnimatedScale(
                          scale: _scale,
                          duration: const Duration(milliseconds: 90),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(toBn(count),
                                  style: const TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.w800)),
                              Text('/ ${toBn(z.target)}',
                                  style: const TextStyle(
                                      color: kMuted, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (done) ...[
                  const Text('মাশাআল্লাহ! ১০০ পূর্ণ হয়েছে, সেভ হয়ে গেছে।',
                      style: TextStyle(
                          color: kAccent, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (hasNext)
                    FilledButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                TasbihCounterPage(index: widget.index + 1)),
                      ),
                      child: const Text('পরের জিকির'),
                    ),
                ] else
                  const Text('যেকোনো জায়গায় ট্যাপ করো',
                      style: TextStyle(color: kMuted)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
