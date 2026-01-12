import 'package:chess_app/models/board.dart';
import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/game.dart';

class Bishop extends ChessPiece{
  const Bishop({required super.owner}) : super(type: 'bishop');

  @override
  List<int> getPossibleMoves(int currentIndex, GameState game) {
    List<int> moves = [];
    final int boardSize = BoardData.boardSize;

    final List<int> directions = [boardSize + 1, boardSize - 1, - boardSize + 1, - boardSize - 1];
    for(int direction in directions){
      for(int index = currentIndex + direction;
      BoardData.onBoard(index)
          && ((index - direction) % boardSize -  index % boardSize).abs() == 1;
      index += direction ){
        if(game.board[index] == null){
          moves.add(index);
        } else if(game.isEnemies(game.board[index]!.owner, owner)){
          moves.add(index);
          break;
        } else{
          break;
        }
      }
    }

    return moves;
  }

  @override
  ChessPiece kill() {
    return Bishop(owner: -1);
  }

}