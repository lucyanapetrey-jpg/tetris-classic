// Teste de logică pură pentru tabla de joc (fără plugin-uri / UI).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_classic/game/board.dart';

void main() {
  test('start() umple tabla cu o piesă curentă, fără game over', () {
    final b = BlockBoard();
    b.start();
    expect(b.current, isNotNull);
    expect(b.next, isNotNull);
  });

  test('clearBottomRows golește rândurile de jos', () {
    final b = BlockBoard();
    b.start();
    for (var c = 0; c < BlockBoard.cols; c++) {
      b.grid[BlockBoard.rows - 1][c] = const Color(0xFF00E5FF);
    }
    final cleared = b.clearBottomRows(2);
    expect(cleared, 2);
    expect(b.grid[BlockBoard.rows - 1].every((cell) => cell == null), isTrue);
  });

  test('clearTopRows eliberează zona de spawn', () {
    final b = BlockBoard();
    b.start();
    b.grid[0][0] = const Color(0xFFFF4081);
    b.clearTopRows(3);
    expect(b.grid[0][0], isNull);
  });
}
