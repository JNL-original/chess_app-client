import 'package:chess_app/models/board.dart';
import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/game.dart';

class Rook extends ChessPiece{
  final bool hasMoved;

  const Rook({required super.owner, this.hasMoved = false})
      : super(type: 'rook');

  Rook copyWith({bool? hasMoved}){
    return Rook(
        owner: owner,
      hasMoved: hasMoved ?? this.hasMoved
    );
  }

  @override
  List<int> getPossibleMoves(int currentIndex, GameState game) {
    List<int> moves = [];
    final boardSize = BoardData.boardSize;
    final currentRow = currentIndex ~/ boardSize;

    for(
      int index = currentIndex + boardSize;
      BoardData.onBoard(index);
      index += boardSize
    ){
      if(game.board[index] == null){
        moves.add(index);
      } else if(game.board[index]?.owner != owner){
        moves.add(index);
        break;
      } else{
        break;
      }
    }

    for(
    int index = currentIndex - boardSize;
    BoardData.onBoard(index);
    index -= boardSize
    ){
      if(game.board[index] == null){
        moves.add(index);
      } else if(game.board[index]?.owner != owner){
        moves.add(index);
        break;
      } else{
        break;
      }
    }

    for(
    int index = currentIndex + 1;
    BoardData.onBoard(index) && index ~/ boardSize == currentRow;
    index++
    ){
      if(game.board[index] == null){
        moves.add(index);
      } else if(game.board[index]?.owner != owner){
        moves.add(index);
        break;
      } else{
        break;
      }
    }

    for(
    int index = currentIndex - 1;
    BoardData.onBoard(index) && index ~/ boardSize == currentRow;
    index--
    ){
      if(game.board[index] == null){
        moves.add(index);
      } else if(game.board[index]?.owner != owner){
        moves.add(index);
        break;
      } else{
        break;
      }
    }

    return moves;
  }

  @override
  ChessPiece kill() {
    return Rook(owner: -1);
  }

}