import 'package:chess_app/models/board.dart';
import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/game.dart';

class Knight extends ChessPiece{
  const Knight({required super.owner})
      : super(type: 'knight');

  @override
  List<int> getPossibleMoves(int currentIndex, GameState game) {
    List<int> moves = [];
    final boardSize = BoardData.boardSize;
    final int currentCol = currentIndex % boardSize;
    final List<int> directions = [
      boardSize * 2 - 1,
      boardSize * 2 + 1,
      - boardSize * 2 - 1,
      - boardSize * 2 + 1,
      boardSize - 2,
      boardSize + 2,
      - boardSize - 2,
      - boardSize + 2
    ];

    for(int direction in directions){
      int index = currentIndex + direction;
      if(!BoardData.onBoard(index)
          || (index % boardSize - currentCol).abs() > 2
          || game.board[index] != null && game.board[index]?.owner == owner){
        continue;
      } else{
        moves.add(index);
      }
    }

    return moves;
  }

  @override
  ChessPiece kill() {
    // TODO: implement kill
    return Knight(owner: -1);
  }

}