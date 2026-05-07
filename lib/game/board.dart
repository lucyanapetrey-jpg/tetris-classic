import 'dart:math';
import 'package:flutter/material.dart';
import 'tetromino.dart';

class TetrisBoard {
  static const int cols = 10;
  static const int rows = 20;

  final List<List<Color?>> grid =
      List.generate(rows, (_) => List<Color?>.filled(cols, null));

  Tetromino? current;
  Tetromino? next;
  final _rng = Random();

  Tetromino _spawn() {
    final types = PieceType.values;
    return Tetromino.fromType(types[_rng.nextInt(types.length)]);
  }

  void start() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        grid[r][c] = null;
      }
    }
    next = _spawn();
    spawn();
  }

  bool spawn() {
    current = next;
    next = _spawn();
    if (current != null && _collides(current!, current!.x, current!.y)) {
      return false; // game over
    }
    return true;
  }

  bool _collides(Tetromino t, int nx, int ny) {
    final s = t.shape;
    for (var i = 0; i < s.length; i++) {
      for (var j = 0; j < s[i].length; j++) {
        if (s[i][j] == 0) continue;
        final r = ny + i;
        final c = nx + j;
        if (c < 0 || c >= cols || r >= rows) return true;
        if (r >= 0 && grid[r][c] != null) return true;
      }
    }
    return false;
  }

  bool moveLeft() {
    if (current == null) return false;
    if (!_collides(current!, current!.x - 1, current!.y)) {
      current!.x--;
      return true;
    }
    return false;
  }

  bool moveRight() {
    if (current == null) return false;
    if (!_collides(current!, current!.x + 1, current!.y)) {
      current!.x++;
      return true;
    }
    return false;
  }

  bool softDrop() {
    if (current == null) return false;
    if (!_collides(current!, current!.x, current!.y + 1)) {
      current!.y++;
      return true;
    }
    return false;
  }

  int hardDrop() {
    if (current == null) return 0;
    var dist = 0;
    while (!_collides(current!, current!.x, current!.y + 1)) {
      current!.y++;
      dist++;
    }
    return dist;
  }

  void rotate() {
    if (current == null) return;
    current!.rotate();
    // simple wall kicks
    final kicks = [0, -1, 1, -2, 2];
    for (final k in kicks) {
      if (!_collides(current!, current!.x + k, current!.y)) {
        current!.x += k;
        return;
      }
    }
    current!.rotateBack();
  }

  // Lock current piece into grid; returns number of cleared lines
  int lock() {
    if (current == null) return 0;
    final s = current!.shape;
    for (var i = 0; i < s.length; i++) {
      for (var j = 0; j < s[i].length; j++) {
        if (s[i][j] == 0) continue;
        final r = current!.y + i;
        final c = current!.x + j;
        if (r >= 0 && r < rows && c >= 0 && c < cols) {
          grid[r][c] = current!.color;
        }
      }
    }
    return _clearLines();
  }

  int _clearLines() {
    var cleared = 0;
    for (var r = rows - 1; r >= 0; r--) {
      if (grid[r].every((cell) => cell != null)) {
        grid.removeAt(r);
        grid.insert(0, List<Color?>.filled(cols, null));
        cleared++;
        r++;
      }
    }
    return cleared;
  }

  // Returns y position where current would land (for ghost piece)
  int ghostY() {
    if (current == null) return 0;
    var y = current!.y;
    while (!_collides(current!, current!.x, y + 1)) {
      y++;
    }
    return y;
  }
}
