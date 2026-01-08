import 'package:chess_app/models/board.dart';
import 'package:chess_app/models/chess_piece.dart';

import 'game.dart';

class King extends ChessPiece{
  final bool hasMoved;

  const King({required super.owner, this.hasMoved = false})
  : super(type: 'king');

  King copyWith({hasMoved}){
    return King(owner: owner, hasMoved: hasMoved ?? this.hasMoved);
  }

  @override
  List<int> getPossibleMoves(int currentIndex, GameState game) {
    List<int> moves = [];
    final int boardSize = BoardData.boardSize;
    final List<int> checkList = [
      currentIndex + boardSize,
      currentIndex - boardSize,
      currentIndex + 1,
      currentIndex - 1,
      currentIndex + boardSize + 1,
      currentIndex + boardSize - 1,
      currentIndex - boardSize + 1,
      currentIndex - boardSize -1
    ];

    for(int index in checkList){
      if(!BoardData.onBoard(index)
          || game.board[index] != null && game.board[index]!.owner == owner){
        continue;
      }

      int currentCol = currentIndex % boardSize;
      int newCol = index % boardSize;

      if((currentCol - newCol).abs() <= 1){
        moves.add(index);
      }
    }

    return moves;
  }

  @override
  ChessPiece kill() {
    return King(owner: -1);
  }
}