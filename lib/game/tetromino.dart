import 'package:flutter/material.dart';

enum PieceType { I, O, T, S, Z, J, L }

class Tetromino {
  final PieceType type;
  final List<List<List<int>>> rotations;
  final Color color;
  int rotationIndex;
  int x; // top-left column
  int y; // top-left row

  Tetromino._(this.type, this.rotations, this.color)
      : rotationIndex = 0,
        x = 3,
        y = 0;

  List<List<int>> get shape => rotations[rotationIndex];

  void rotate() {
    rotationIndex = (rotationIndex + 1) % rotations.length;
  }

  void rotateBack() {
    rotationIndex = (rotationIndex - 1 + rotations.length) % rotations.length;
  }

  static Tetromino fromType(PieceType t) {
    switch (t) {
      case PieceType.I:
        return Tetromino._(t, [
          [
            [0, 0, 0, 0],
            [1, 1, 1, 1],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
          [
            [0, 0, 1, 0],
            [0, 0, 1, 0],
            [0, 0, 1, 0],
            [0, 0, 1, 0],
          ],
        ], const Color(0xFF22D3EE)); // I cyan
      case PieceType.O:
        return Tetromino._(t, [
          [
            [1, 1],
            [1, 1],
          ],
        ], const Color(0xFFFBBF24)); // O amber
      case PieceType.T:
        return Tetromino._(t, [
          [
            [0, 1, 0],
            [1, 1, 1],
            [0, 0, 0],
          ],
          [
            [0, 1, 0],
            [0, 1, 1],
            [0, 1, 0],
          ],
          [
            [0, 0, 0],
            [1, 1, 1],
            [0, 1, 0],
          ],
          [
            [0, 1, 0],
            [1, 1, 0],
            [0, 1, 0],
          ],
        ], const Color(0xFFA855F7)); // T purple
      case PieceType.S:
        return Tetromino._(t, [
          [
            [0, 1, 1],
            [1, 1, 0],
            [0, 0, 0],
          ],
          [
            [0, 1, 0],
            [0, 1, 1],
            [0, 0, 1],
          ],
        ], const Color(0xFF34D399)); // S emerald
      case PieceType.Z:
        return Tetromino._(t, [
          [
            [1, 1, 0],
            [0, 1, 1],
            [0, 0, 0],
          ],
          [
            [0, 0, 1],
            [0, 1, 1],
            [0, 1, 0],
          ],
        ], const Color(0xFFF43F5E)); // Z rose
      case PieceType.J:
        return Tetromino._(t, [
          [
            [1, 0, 0],
            [1, 1, 1],
            [0, 0, 0],
          ],
          [
            [0, 1, 1],
            [0, 1, 0],
            [0, 1, 0],
          ],
          [
            [0, 0, 0],
            [1, 1, 1],
            [0, 0, 1],
          ],
          [
            [0, 1, 0],
            [0, 1, 0],
            [1, 1, 0],
          ],
        ], const Color(0xFF3B82F6)); // J blue
      case PieceType.L:
        return Tetromino._(t, [
          [
            [0, 0, 1],
            [1, 1, 1],
            [0, 0, 0],
          ],
          [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
          ],
          [
            [0, 0, 0],
            [1, 1, 1],
            [1, 0, 0],
          ],
          [
            [1, 1, 0],
            [0, 1, 0],
            [0, 1, 0],
          ],
        ], const Color(0xFFFB923C)); // L orange
    }
  }
}
