import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/game.dart';

import 'board.dart';

class Queen extends ChessPiece{
  const Queen({required super.owner}) : super(type: 'queen');

  @override
  List<int> getPossibleMoves(int currentIndex, GameState game) {
    List<int> moves = [];
    final boardSize = BoardData.boardSize;
    final currentRow = currentIndex ~/ boardSize;

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

    for(
    int index = currentIndex + boardSize;
    BoardData.onBoard(index);
    index += boardSize
    ){
      if(game.board[index] == null){
        moves.add(index);
      } else if(game.isEnemies(game.board[index]!.owner, owner)){
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
      } else if(game.isEnemies(game.board[index]!.owner, owner)){
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
      } else if(game.isEnemies(game.board[index]!.owner, owner)){
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
      } else if(game.isEnemies(game.board[index]!.owner, owner)){
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
    return Queen(owner: -1);
  }

}