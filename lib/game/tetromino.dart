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
        ], const Color(0xFF00E5FF));
      case PieceType.O:
        return Tetromino._(t, [
          [
            [1, 1],
            [1, 1],
          ],
        ], const Color(0xFFFFEB3B));
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
        ], const Color(0xFFAB47BC));
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
        ], const Color(0xFF66BB6A));
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
        ], const Color(0xFFEF5350));
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
        ], const Color(0xFF42A5F5));
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
        ], const Color(0xFFFF9800));
    }
  }
}
