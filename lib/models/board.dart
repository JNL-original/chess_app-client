import 'package:chess_app/configs/config.dart';
import 'package:chess_app/models/queen.dart';
import 'package:chess_app/models/bishop.dart';
import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/king.dart';
import 'package:chess_app/models/knight.dart';
import 'package:chess_app/models/pawn.dart';
import 'package:chess_app/models/rook.dart';


class BoardData{
  static const boardSize = 14;
  static const totalTiles = boardSize*boardSize;
  static const corners = [
    0,   1,   2,        11,  12,  13,
    14,  15,  16,       25,  26,  27,
    28,  29,  30,       39,  40,  41,

    154, 155, 156,     165, 166, 167,
    168, 169, 170,     179, 180, 181,
    182, 183, 184,     193, 194, 195,
  ]; //если их перезаписывать надо еще поменять promotion conditions

  static List<ChessPiece?> initialBoard = List.generate(
      totalTiles, (index)=>null);



  static List<ChessPiece?> initializePieces(GameConfig config){
    final board = List<ChessPiece?>.from(initialBoard);


    // --- ИГРОК 2 (СВЕРХУ) ---
    // Фигуры: ряд 0, Пешки: ряд 1
    _setRow(board, 0, 2, isTopOrBottom: true);
    _setPawnsRow(board, 1, 2, isHorizontal: true);

    // --- ИГРОК 0 (ВНИЗУ) ---
    // Фигуры: ряд 13, Пешки: ряд 12
    _setRow(board, 13, 0, isTopOrBottom: true);
    _setPawnsRow(board, 12, 0, isHorizontal: true);

    // --- ИГРОК 1 (СЛЕВА) ---
    // Фигуры: столбец 0, Пешки: столбец 1
    _setColumn(board, 0, 1);
    _setPawnsRow(board, 1, 1, isHorizontal: false);

    // --- ИГРОК 3 (СПРАВА) ---
    // Фигуры: столбец 13, Пешки: столбец 12
    _setColumn(board, 13, 3);
    _setPawnsRow(board, 12, 3, isHorizontal: false);

    return board;
  }

  static bool onBoard(int index){
    if(index >= 0 && index < totalTiles && !corners.contains(index)) {
      return true;
    }
    return false;
  }



  // Вспомогательный метод для расстановки тяжелых фигур в горизонтальных рядах (Верх/Низ)
  static void _setRow(List<ChessPiece?> board, int row, int owner, {required bool isTopOrBottom}) {
    int start = row * 14 + 3; // Пропускаем 3 пустые клетки угла
    List<ChessPiece> pieces = [
      Rook(owner: owner), Knight(owner: owner), Bishop(owner: owner),
      Queen(owner: owner), King(owner: owner),
      Bishop(owner: owner), Knight(owner: owner), Rook(owner: owner),
    ];

    // Для верхнего игрока Король и Ферзь обычно меняются местами, чтобы стоять друг напротив друга
    if (row == 0) {
      var temp = pieces[3];
      pieces[3] = pieces[4];
      pieces[4] = temp;
    }

    for (int i = 0; i < pieces.length; i++) {
      board[start + i] = pieces[i];
    }
  }

// Вспомогательный метод для вертикальных столбцов (Лево/Право)
  static void _setColumn(List<ChessPiece?> board, int col, int owner) {
    int startOffset = 3 * 14 + col; // Начинаем с 3-й строки
    List<ChessPiece> pieces = [
      Rook(owner: owner), Knight(owner: owner), Bishop(owner: owner),
      Queen(owner: owner), King(owner: owner),
      Bishop(owner: owner), Knight(owner: owner), Rook(owner: owner),
    ];

    // Для правого игрока инвертируем порядок, чтобы ферзи смотрели друг на друга
    if (col == 13) {
      var temp = pieces[3];
      pieces[3] = pieces[4];
      pieces[4] = temp;
    }

    for (int i = 0; i < pieces.length; i++) {
      board[startOffset + (i * 14)] = pieces[i];
    }
  }

// Вспомогательный метод для пешек
  static void _setPawnsRow(List<ChessPiece?> board, int index, int owner, {required bool isHorizontal}) {
    if (isHorizontal) {
      int start = index * 14 + 3;
      for (int i = 0; i < 8; i++) {
        board[start + i] = Pawn(owner: owner);
      }
    } else {
      int start = 3 * 14 + index;
      for (int i = 0; i < 8; i++) {
        board[start + (i * 14)] = Pawn(owner: owner);
      }
    }
  }
}