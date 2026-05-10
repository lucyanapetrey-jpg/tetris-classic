import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/app_strings.dart';
import '../game/board.dart';
import '../game/tetromino.dart';
import '../services/ad_service.dart';
import '../services/rewards_service.dart';

class Particle {
  double x, y, vx, vy, life, size;
  Color color;
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color);
}

class ScorePopup {
  final String text;
  final double x, y;
  double life;
  final Color color;
  ScorePopup(this.text, this.x, this.y, this.life, this.color);
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final TetrisBoard _board = TetrisBoard();
  final _rewards = RewardsService();
  Timer? _timer;
  Timer? _animTimer;
  int _score = 0;
  int _level = 1;
  int _lines = 0;
  int _combo = 0;
  int _blocksPlaced = 0;
  static const int _adEveryNBlocks = 20;
  bool _over = false;
  bool _paused = false;
  final List<Particle> _particles = [];
  final List<ScorePopup> _popups = [];
  late AnimationController _bgAnim;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _board.start();
    _startTick();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _animTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      _stepAnimations();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animTimer?.cancel();
    _bgAnim.dispose();
    super.dispose();
  }

  void _stepAnimations() {
    if (_particles.isEmpty && _popups.isEmpty) return;
    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.4;
        p.life -= 0.03;
      }
      _particles.removeWhere((p) => p.life <= 0);
      for (final p in _popups) {
        p.life -= 0.025;
      }
      _popups.removeWhere((p) => p.life <= 0);
    });
  }

  void _startTick() {
    _timer?.cancel();
    final ms = (1000 - (_level - 1) * 80).clamp(80, 1000);
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (_paused || _over) return;
      _tick();
    });
  }

  void _tick() {
    setState(() {
      if (!_board.softDrop()) {
        final lines = _board.lock();
        _addScore(lines, false);
        _onBlockLocked();
        if (!_board.spawn()) {
          _over = true;
          _timer?.cancel();
          _saveHighScore();
        }
      }
    });
  }

  void _onBlockLocked() {
    _blocksPlaced++;
    if (_blocksPlaced % _adEveryNBlocks == 0) {
      AdService().showInterstitial();
    }
  }

  void _addScore(int lines, bool isHardDrop) {
    if (lines > 0) {
      const points = [0, 40, 100, 300, 1200];
      final base = points[lines] * _level;
      _combo++;
      final comboBonus = _combo > 1 ? (_combo - 1) * 50 * _level : 0;
      final total = base + comboBonus;
      _score += total;
      _lines += lines;
      // Particle burst
      _spawnParticles(lines);
      // Popup
      String label;
      Color popupColor = const Color(0xFF00E5FF);
      if (lines == 4) {
        label = 'TETRIS! +$total';
        popupColor = const Color(0xFFFFD740);
        _rewards.addCoins(20);
      } else if (lines == 3) {
        label = 'TRIPLE! +$total';
        popupColor = const Color(0xFFE91E63);
        _rewards.addCoins(10);
      } else if (lines == 2) {
        label = 'DOUBLE! +$total';
        popupColor = const Color(0xFFAB47BC);
        _rewards.addCoins(5);
      } else {
        label = '+$total';
      }
      if (_combo > 1) label += '\nCOMBO x$_combo';
      _popups.add(ScorePopup(label, 0.5, 0.4, 1.0, popupColor));
      HapticFeedback.heavyImpact();
      final newLevel = (_lines ~/ 10) + 1;
      if (newLevel != _level) {
        _level = newLevel;
        _startTick();
        _popups.add(ScorePopup('LEVEL $_level!', 0.5, 0.5, 1.5, const Color(0xFFFF6F00)));
      }
    } else {
      _combo = 0;
    }
  }

  void _spawnParticles(int lines) {
    for (var i = 0; i < 20 * lines; i++) {
      final color = [
        const Color(0xFF00E5FF),
        const Color(0xFFFF4081),
        const Color(0xFFFFEB3B),
        const Color(0xFF66BB6A),
        const Color(0xFFFFFFFF),
      ][_rng.nextInt(5)];
      _particles.add(Particle(
        _rng.nextDouble(), 0.5,
        (_rng.nextDouble() - 0.5) * 0.04,
        -_rng.nextDouble() * 0.04,
        1.0, 4 + _rng.nextDouble() * 6,
        color,
      ));
    }
  }

  Future<void> _saveHighScore() async {
    final p = await SharedPreferences.getInstance();
    final hs = p.getInt('highScore') ?? 0;
    if (_score > hs) await p.setInt('highScore', _score);
    if (_score >= 1000) await _rewards.addCoins(50);
  }

  void _hardDrop() {
    setState(() {
      final dist = _board.hardDrop();
      _score += dist * 2;
      final lines = _board.lock();
      _addScore(lines, true);
      _onBlockLocked();
      if (!_board.spawn()) {
        _over = true;
        _timer?.cancel();
        _saveHighScore();
      }
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (ctx, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF0D0D14), const Color(0xFF1A0F2E),
                    (sin(_bgAnim.value * 2 * pi) + 1) / 2)!,
                Color.lerp(const Color(0xFF1A1A2E), const Color(0xFF0D0F2A),
                    (sin(_bgAnim.value * 2 * pi + pi / 2) + 1) / 2)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                _statsBar(),
                Expanded(child: _gameArea()),
                _controls(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFFAB47BC)],
            ).createShader(r),
            child: const Text('TETRIS SMILE',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4)),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause, color: Colors.white),
            onPressed: () => setState(() => _paused = !_paused),
          ),
        ],
      ),
    );
  }

  Widget _statsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(AppStrings.of(context).score, '$_score', const Color(0xFF00E5FF)),
          _stat('Level', '$_level', const Color(0xFFFFD740)),
          _stat('Lines', '$_lines', const Color(0xFF66BB6A)),
          _stat('Combo', 'x$_combo', _combo > 1 ? const Color(0xFFE91E63) : Colors.white60),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1)),
        Text(value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _gameArea() {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (_paused || _over) return;
        setState(() {
          if (d.primaryVelocity! > 0) {
            _board.moveRight();
          } else {
            _board.moveLeft();
          }
        });
      },
      onTap: () {
        if (_paused || _over) return;
        setState(() => _board.rotate());
      },
      onVerticalDragEnd: (d) {
        if (_paused || _over) return;
        if ((d.primaryVelocity ?? 0) > 1500) _hardDrop();
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AspectRatio(
            aspectRatio: TetrisBoard.cols / TetrisBoard.rows,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x4400E5FF), blurRadius: 16, spreadRadius: 1),
                ],
              ),
              child: LayoutBuilder(builder: (c, cons) {
              final cellW = cons.maxWidth / TetrisBoard.cols;
              final cellH = cons.maxHeight / TetrisBoard.rows;
              return Stack(
                children: [
                  CustomPaint(
                    size: Size(cons.maxWidth, cons.maxHeight),
                    painter: _GridPainter(),
                  ),
                  for (var r = 0; r < TetrisBoard.rows; r++)
                    for (var c2 = 0; c2 < TetrisBoard.cols; c2++)
                      if (_board.grid[r][c2] != null)
                        Positioned(
                          left: c2 * cellW,
                          top: r * cellH,
                          width: cellW,
                          height: cellH,
                          child: _block(_board.grid[r][c2]!),
                        ),
                  if (_board.current != null && !_over) ..._renderGhost(cellW, cellH),
                  if (_board.current != null) ..._renderCurrent(cellW, cellH),
                  // Particles
                  for (final p in _particles)
                    Positioned(
                      left: p.x * cons.maxWidth - p.size / 2,
                      top: p.y * cons.maxHeight - p.size / 2,
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          color: p.color.withValues(alpha: p.life.clamp(0, 1)),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: p.color, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  // Popups
                  for (final p in _popups)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: p.y * cons.maxHeight,
                      child: Center(
                        child: Opacity(
                          opacity: p.life.clamp(0, 1),
                          child: Transform.scale(
                            scale: 1 + (1 - p.life) * 0.3,
                            child: Text(
                              p.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: p.color,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(color: p.color, blurRadius: 12),
                                  const Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_over) _gameOverOverlay(),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.of(context).gameOver,
                style: const TextStyle(
                    color: Color(0xFFEF5350),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4)),
            const SizedBox(height: 8),
            Text('${AppStrings.of(context).score}: $_score',
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              onPressed: () {
                setState(() {
                  _board.start();
                  _score = 0;
                  _level = 1;
                  _lines = 0;
                  _combo = 0;
                  _blocksPlaced = 0;
                  _over = false;
                });
                _startTick();
              },
              child: Text(AppStrings.of(context).again),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _renderCurrent(double cellW, double cellH) {
    final t = _board.current!;
    final widgets = <Widget>[];
    for (var i = 0; i < t.shape.length; i++) {
      for (var j = 0; j < t.shape[i].length; j++) {
        if (t.shape[i][j] == 0) continue;
        widgets.add(Positioned(
          left: (t.x + j) * cellW,
          top: (t.y + i) * cellH,
          width: cellW,
          height: cellH,
          child: _block(t.color),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _renderGhost(double cellW, double cellH) {
    final t = _board.current!;
    final gy = _board.ghostY();
    final widgets = <Widget>[];
    for (var i = 0; i < t.shape.length; i++) {
      for (var j = 0; j < t.shape[i].length; j++) {
        if (t.shape[i][j] == 0) continue;
        widgets.add(Positioned(
          left: (t.x + j) * cellW,
          top: (gy + i) * cellH,
          width: cellW,
          height: cellH,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: t.color.withValues(alpha: 0.4), width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _block(Color color) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.7),
            color,
            color.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.5, 1],
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
        ],
      ),
      child: Stack(
        children: [
          // top-left highlight
          Positioned(
            top: 1,
            left: 1,
            right: 1,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _ctrlBtn(Icons.chevron_left, () => setState(() => _board.moveLeft()),
              const Color(0xFF00E5FF)),
          _ctrlBtn(Icons.rotate_right, () => setState(() => _board.rotate()),
              const Color(0xFFAB47BC)),
          _ctrlBtn(Icons.chevron_right, () => setState(() => _board.moveRight()),
              const Color(0xFF00E5FF)),
          _ctrlBtn(Icons.arrow_downward, () => setState(() => _board.softDrop()),
              const Color(0xFF66BB6A)),
          _ctrlBtn(Icons.keyboard_double_arrow_down, _hardDrop,
              const Color(0xFFFFD740), accent: true),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap, Color color,
      {bool accent = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () {
            if (!_over && !_paused) {
              onTap();
              HapticFeedback.lightImpact();
            }
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: accent
                    ? [color, color.withValues(alpha: 0.7)]
                    : [
                        const Color(0xFF1E1B30).withValues(alpha: 0.85),
                        const Color(0xFF120F22).withValues(alpha: 0.95),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: accent ? 0.9 : 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: accent ? 0.6 : 0.25),
                  blurRadius: accent ? 16 : 10,
                  spreadRadius: accent ? 1 : 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: accent ? Colors.black : color,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    final cellW = size.width / TetrisBoard.cols;
    final cellH = size.height / TetrisBoard.rows;
    for (var i = 0; i <= TetrisBoard.cols; i++) {
      canvas.drawLine(Offset(i * cellW, 0), Offset(i * cellW, size.height), paint);
    }
    for (var i = 0; i <= TetrisBoard.rows; i++) {
      canvas.drawLine(Offset(0, i * cellH), Offset(size.width, i * cellH), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
