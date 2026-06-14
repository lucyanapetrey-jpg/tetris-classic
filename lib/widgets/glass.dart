import 'dart:ui';
import 'package:flutter/material.dart';

/// Card de sticlă mată (glassmorphism) reutilizabil — blur real prin
/// [BackdropFilter] + tentă translucidă + chenar luminos + highlight sus.
/// Identitatea Block Smile: accente neon (cyan/violet/magenta).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color tint;
  final Color borderColor;
  final Color? glowColor;
  final double glowBlur;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.blur = 18,
    this.tint = const Color(0x1FFFFFFF),
    this.borderColor = const Color(0x4DFFFFFF),
    this.glowColor,
    this.glowBlur = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget card = DecoratedBox(
      // glow exterior (umbra colorata, nu se taie de clip)
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.35),
                  blurRadius: glowBlur,
                  spreadRadius: 1,
                ),
              ]
            : const [
                BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 12)),
              ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              // tenta + highlight diagonal de sticla
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  tint,
                  Colors.white.withValues(alpha: 0.04),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
    if (onTap != null) {
      card = GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
    }
    return card;
  }
}

/// Fundal animat subtil: gradient de bază + cateva halouri neon care plutesc
/// lent. Reutilizabil pe ecrane (home). Discret, fără consum mare.
class NeonBackdrop extends StatefulWidget {
  final Widget child;
  const NeonBackdrop({super.key, required this.child});

  @override
  State<NeonBackdrop> createState() => _NeonBackdropState();
}

class _NeonBackdropState extends State<NeonBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF120A24), Color(0xFF1C1140), Color(0xFF0C0A1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          return Stack(
            children: [
              _blob(const Color(0xFF00E5FF), -60 + 30 * t, 80 + 40 * t, 320),
              _blob(const Color(0xFFAB47BC), 220 - 40 * t, 360 + 50 * t, 360),
              _blob(const Color(0xFFFF4081), 120 + 50 * t, 620 - 30 * t, 300),
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }

  Widget _blob(Color color, double left, double top, double size) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.40), color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Buton mare „neon glass" pentru acțiunea principală (PLAY).
class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final List<Color> colors;
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.colors = const [Color(0xFF00E5FF), Color(0xFF2EA8FF)],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(color: colors.first.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 1),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // highlight lucios sus
            Positioned(
              top: 4, left: 16, right: 16,
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
