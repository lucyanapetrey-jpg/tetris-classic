import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/board.dart';
import '../game/tetromino.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TetrisBoard _board = TetrisBoard();
  Timer? _timer;
  int _score = 0;
  int _level = 1;
  int _lines = 0;
  bool _over = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _board.start();
    _startTick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
        if (!_board.spawn()) {
          _over = true;
          _timer?.cancel();
          _saveHighScore();
        }
      }
    });
  }

  void _addScore(int lines, bool isHardDrop) {
    if (lines > 0) {
      const points = [0, 40, 100, 300, 1200];
      _score += points[lines] * _level;
      _lines += lines;
      final newLevel = (_lines ~/ 10) + 1;
      if (newLevel != _level) {
        _level = newLevel;
        _startTick();
      }
    }
  }

  Future<void> _saveHighScore() async {
    final p = await SharedPreferences.getInstance();
    final hs = p.getInt('highScore') ?? 0;
    if (_score > hs) await p.setInt('highScore', _score);
  }

  void _hardDrop() {
    setState(() {
      final dist = _board.hardDrop();
      _score += dist * 2;
      final lines = _board.lock();
      _addScore(lines, true);
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
      appBar: AppBar(
        title: const Text('Tetris Classic'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() => _paused = !_paused),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _statsBar(),
            Expanded(child: _gameArea()),
            _controls(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _statsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Score', '$_score'),
          _stat('Level', '$_level'),
          _stat('Lines', '$_lines'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF00E5FF), fontSize: 22, fontWeight: FontWeight.w900)),
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
        if ((d.primaryVelocity ?? 0) > 1500) {
          _hardDrop();
        }
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: TetrisBoard.cols / TetrisBoard.rows,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: const Color(0xFF00E5FF), width: 2),
            ),
            child: LayoutBuilder(builder: (c, cons) {
              final cell = cons.maxWidth / TetrisBoard.cols;
              return Stack(
                children: [
                  // Grid
                  for (var r = 0; r < TetrisBoard.rows; r++)
                    for (var c2 = 0; c2 < TetrisBoard.cols; c2++)
                      if (_board.grid[r][c2] != null)
                        Positioned(
                          left: c2 * cell,
                          top: r * cell,
                          width: cell,
                          height: cell,
                          child: _block(_board.grid[r][c2]!),
                        ),
                  // Ghost piece
                  if (_board.current != null && !_over) ..._renderGhost(cell),
                  // Current piece
                  if (_board.current != null) ..._renderCurrent(cell),
                  if (_over)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black87,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('GAME OVER',
                                style: TextStyle(
                                    color: Color(0xFFEF5350),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4)),
                            const SizedBox(height: 8),
                            Text('Score: $_score',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _board.start();
                                  _score = 0;
                                  _level = 1;
                                  _lines = 0;
                                  _over = false;
                                });
                                _startTick();
                              },
                              child: const Text('Din nou'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  List<Widget> _renderCurrent(double cell) {
    final t = _board.current!;
    final widgets = <Widget>[];
    for (var i = 0; i < t.shape.length; i++) {
      for (var j = 0; j < t.shape[i].length; j++) {
        if (t.shape[i][j] == 0) continue;
        widgets.add(Positioned(
          left: (t.x + j) * cell,
          top: (t.y + i) * cell,
          width: cell,
          height: cell,
          child: _block(t.color),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _renderGhost(double cell) {
    final t = _board.current!;
    final gy = _board.ghostY();
    final widgets = <Widget>[];
    for (var i = 0; i < t.shape.length; i++) {
      for (var j = 0; j < t.shape[i].length; j++) {
        if (t.shape[i][j] == 0) continue;
        widgets.add(Positioned(
          left: (t.x + j) * cell,
          top: (gy + i) * cell,
          width: cell,
          height: cell,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: t.color.withValues(alpha: 0.4), width: 1.5),
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
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
        ],
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ctrlBtn(Icons.arrow_left, () => setState(() => _board.moveLeft())),
          _ctrlBtn(Icons.rotate_right, () => setState(() => _board.rotate())),
          _ctrlBtn(Icons.arrow_right, () => setState(() => _board.moveRight())),
          _ctrlBtn(Icons.arrow_drop_down, () => setState(() => _board.softDrop())),
          _ctrlBtn(Icons.vertical_align_bottom, _hardDrop),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (!_over && !_paused) {
                onTap();
                HapticFeedback.lightImpact();
              }
            },
            child: SizedBox(
              height: 56,
              child: Icon(icon, color: const Color(0xFF00E5FF), size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
