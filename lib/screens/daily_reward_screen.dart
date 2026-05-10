import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n/app_strings.dart';
import '../services/rewards_service.dart';

class DailyRewardScreen extends StatefulWidget {
  final int day;
  final int reward;
  const DailyRewardScreen({super.key, required this.day, required this.reward});

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.6, end: 1.0).animate(
                    CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
                  ),
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFFAB47BC)],
                    ).createShader(r),
                    child: const Icon(Icons.auto_awesome, size: 100, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFFFFD740)],
                  ).createShader(r),
                  child: Text(s.dailyBonus,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4)),
                ),
                const SizedBox(height: 8),
                Text(s.dayOf7.replaceAll('{n}', '${widget.day}'),
                    style: const TextStyle(color: Colors.white60, fontSize: 16)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x4400E5FF), blurRadius: 16)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD740), size: 48),
                      const SizedBox(width: 12),
                      Text('+${widget.reward}',
                          style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD740))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final claimed = day <= widget.day;
                    final isToday = day == widget.day;
                    return Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                            : (claimed ? Colors.green.withValues(alpha: 0.3) : Colors.white12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday ? const Color(0xFF00E5FF) : Colors.white24,
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Z$day',
                              style: TextStyle(
                                  color: claimed ? Colors.white : Colors.white60,
                                  fontSize: 11)),
                          const SizedBox(height: 4),
                          if (claimed)
                            const Icon(Icons.check, color: Colors.white, size: 18)
                          else
                            const Icon(Icons.monetization_on, color: Color(0xFFFFD740), size: 18),
                          Text('${RewardsService.dailyRewards[i]}',
                              style: TextStyle(
                                  color: claimed ? Colors.white : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.claim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
