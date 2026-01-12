

import 'package:chess_app/models/board.dart';
import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/game.dart';

class Pawn extends ChessPiece{
  final bool hasMoved;


  const Pawn({
    required super.owner,
    this.hasMoved = false,
  }) : super(type: 'pawn');
  Pawn copyWith({bool? hasMoved}){
    return Pawn(
      owner: owner,
      hasMoved: hasMoved ?? this.hasMoved,
    );
  }

  @override
  List<int> getPossibleMoves(int currentIndex, GameState game) {
    final List<int> moves = [];

    const int boardSize = BoardData.boardSize;

    final int direction;
    final List<int> attackOffsets;
    switch(owner){
      case 0:
        direction = - boardSize;
        attackOffsets = [direction - 1, direction + 1];
      case 1:
        direction = 1;
        attackOffsets = [direction - 14, direction + 14];
      case 2:
        direction = boardSize;
        attackOffsets = [direction - 1, direction + 1];
      case 3:
        direction = -1;
        attackOffsets = [direction - 14, direction + 14];
      default:
        direction = 0;
        attackOffsets = [0];
    }

    final int oneStepIndex = currentIndex + direction;
    if(BoardData.onBoard(oneStepIndex)
        && game.board[oneStepIndex] == null){
      moves.add(oneStepIndex);

      final twoStepIndex = currentIndex + 2 * direction;
      if(!hasMoved && BoardData.onBoard(twoStepIndex)
        && game.board[twoStepIndex] == null){
        moves.add(twoStepIndex);
      }
    }


    for (final offset in attackOffsets) {
      final int attackIndex = currentIndex + offset;

      //Чтобы пешка не прыгала через доску
      final int currentRow = currentIndex ~/ boardSize;
      final int newRow = attackIndex ~/ boardSize;

      if (BoardData.onBoard(attackIndex) //если клетка существует
          && (currentRow - newRow).abs() == 1){
        final targetPiece = game.board[attackIndex];
        if(targetPiece == null){ //если клетка пустая проверка на enPassant
          for(int key in game.enPassant.keys){
            if(game.enPassant[key]![0] == attackIndex && game.board[game.enPassant[key]![1]]!.owner == key && game.isEnemies(owner, key)){
              moves.add(attackIndex);
            }
          }
        }
        else if(game.isEnemies(targetPiece.owner, owner)) {//если клетка вражеская
          moves.add(attackIndex);
        }

      }
    }
    return moves;
  }


  @override
  ChessPiece kill() {
    return Pawn(owner: -1);
  }

  int checkEnPassant(int fromIndex, int toIndex){ //возвращает -1 если был обычный ход и индекс enPassed если был enPassed
    final int direction;
    switch(owner){
      case 0:
        direction = - BoardData.boardSize;
      case 1:
        direction = 1;
      case 2:
        direction = BoardData.boardSize;
      case 3:
        direction = -1;
      default:
        direction = 0;
    }
    if(fromIndex + 2 * direction == toIndex){
      return fromIndex + direction;
    }
    return -1;
  }

  bool isFinished(int index, int promotionCondition){
    if(promotionCondition == 0){
      switch(owner){
        case 0:
          return [42, 43, 44, 55, 54, 53].contains(index) || index < 14;
        case 1:
          return [10, 24, 38, 192, 178, 164].contains(index) || index % 14 == 13;
        case 2:
          return [140, 141, 142, 153, 152, 151].contains(index) || index > 182;
        case 3:
          return [3, 17, 31, 157, 171, 185].contains(index) || index % 14 == 0;
        default:
          return false;
      }
    }
    switch(owner){
      case 0:
        return index ~/ BoardData.boardSize <= BoardData.boardSize - promotionCondition;
      case 1:
        return index % BoardData.boardSize >= promotionCondition - 1;
      case 2:
        return index ~/ BoardData.boardSize >= promotionCondition - 1;
      case 3:
        return index % BoardData.boardSize <= BoardData.boardSize - promotionCondition;
      default:
        return false;
    }
  }
  
}