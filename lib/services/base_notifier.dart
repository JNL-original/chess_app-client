// Оффлайн логика
import 'package:chess_app/configs/config.dart';
import 'package:chess_app/models/chess_piece.dart';

import '../models/board.dart';
import '../models/game.dart';
import '../models/king.dart';
import '../models/rook.dart';

mixin GameBaseNotifier{
  GameState get state;
  set state(GameState value);

  bool makeMove(int fromIndex, int toIndex);//возвращает false если ход невалидный
  Stalemate? checkmate(); //проверить на мат или невозможность ходить текущего игрока
  void nextPlayer();//меняет текущего игрока на следующего
  void continueGameAfterPromotion(ChessPiece piece); //продолжает игру после выбора, в кого превратится пешка

  void onTileTapped(int index){//клиент метод
    if(state.selectedIndex != -1
        && state.availableMoves.contains(index) && state.status == GameStatus.active){
      if(state.myPlayerIndex != -1 && state.myPlayerIndex != state.currentPlayer) return;//если в режиме онлайн не твой ход
      if(makeMove(state.selectedIndex, index)){
        if(state.status == GameStatus.waitingForPromotion || state.config is OnlineConfig) return;
        state = state.copyWith(selectedIndex: -1, availableMoves: []);
        nextPlayer();
      }
      else{
        print("Ошибка хода");
      }

    }
    else if(state.selectedIndex == index || BoardData.corners.contains(index)){
      state = state.copyWith(selectedIndex: -1, availableMoves: []);
    }
    else if (state.board[index] != null && state.currentPlayer == state.board[index]!.owner){
      state = state.copyWith(
          selectedIndex: index,
          availableMoves: _truePossibleMoves(index)
      );
    } else {
      state = state.copyWith(selectedIndex: -1, availableMoves: []);
    }
  }







  bool onFire(int index, List<ChessPiece?> board){//не учитываем en passant и рокировки
    ChessPiece? piece = board[index];

    if(piece == null) return false;

    for(int i = 0; i < board.length; i++){
      ChessPiece? enemyPiece = board[i];
      if(
      enemyPiece != null &&
          state.isEnemies(enemyPiece.owner, piece.owner) &&
          enemyPiece.getPossibleMoves(i, state.copyWith(board: board)).contains(index)
      ) {
        return true;
      }
    }
    return false;
  }

  List<int> _truePossibleMoves(int index){
    ChessPiece? piece = state.board[index];
    if(piece == null) return [];
    List<int> moves = piece.getPossibleMoves(index, state);

    if(state.config.onlyRegicide){
      if(piece.type == 'king') moves.addAll(_possibleCastling());
      return moves;
    }

    List<ChessPiece?> draw = List<ChessPiece?>.of(state.board);
    List<int> kings = List<int>.of(state.kings);


    for(int move in List<int>.of(moves)){ //перебираю каждый возможный ход    без учета enPassant и рокировки
      ChessPiece? temp = draw[move];
      draw[index] = null;
      draw[move] = piece;
      if(piece.type == 'king') kings[state.currentPlayer] = move;
      if(onFire(kings[state.currentPlayer], draw)){
        moves.remove(move);
      }
      draw[move] = temp;
      draw[index] = piece;
      kings[state.currentPlayer] = state.kings[state.currentPlayer];
    }

    if(piece.type == 'king') moves.addAll(_possibleCastling());

    return moves;
  }


  List<int> _possibleCastling(){
    List<int> possible = [];
    List<ChessPiece?> board = state.board;
    if((board[state.kings[state.currentPlayer]] as King).hasMoved) return [];
    List<int> rooks = [];
    for(int i = 0; i < board.length; i++){
      if(board[i] != null && board[i]!.type == 'rook' && board[i]!.owner == state.currentPlayer && !(board[i] as Rook).hasMoved){
        rooks.add(i);
      }
    }
    if(rooks.isEmpty) return [];
    for(int rookIndex in rooks){
      if(_cleanWayForCastling(rookIndex)){
        possible.add(rookIndex);
      }
    }
    return possible;
  }

  bool _cleanWayForCastling(int rookIndex){
    int kingIndex = state.kings[state.currentPlayer];
    if(rookIndex < kingIndex){
      switch(state.currentPlayer){
        case 0:
          for(int x = rookIndex+1; x < kingIndex; x++) {
            if (state.board[x] != null) return false;
          }
        case 1:
          for(int x = rookIndex + BoardData.boardSize; x < kingIndex; x += BoardData.boardSize){
            if (state.board[x] != null) return false;
          }
        case 2:
          for(int x = rookIndex+1; x < kingIndex; x++){
            if (state.board[x] != null) return false;
          }
        case 3:
          for(int x = rookIndex + BoardData.boardSize; x < kingIndex; x += BoardData.boardSize){
            if (state.board[x] != null) return false;
          }
        default:
          return false;
      }
    }
    else{
      switch(state.currentPlayer){
        case 0:
          for (int x = rookIndex-1; x > kingIndex; x--){
            if (state.board[x] != null) return false;
          }
        case 1:
          for (int x = rookIndex - BoardData.boardSize; x > kingIndex; x -= BoardData.boardSize){
            if (state.board[x] != null) return false;
          }
        case 2:
          for (int x = rookIndex-1; x > kingIndex; x--){
            if (state.board[x] != null) return false;
          }
        case 3:
          for (int x = rookIndex - BoardData.boardSize; x > kingIndex; x -= BoardData.boardSize){
            if (state.board[x] != null) return false;
          }
        default:
          return false;
      }
    }

    if(rookIndex < kingIndex){
      switch(state.currentPlayer){
        case 0:
          for(int index = kingIndex; index + 3 > kingIndex; index--){
            if(onFire(index, state.board)) return false;
          }
        case 1:
          for(int index = kingIndex; index + 3 * BoardData.boardSize > kingIndex; index-=BoardData.boardSize){
            if(onFire(index, state.board)) return false;
          }
        case 2:
          for(int index = kingIndex; index + 3 > kingIndex; index--){
            if(onFire(index, state.board)) return false;
          }
        case 3:
          for(int index = kingIndex; index + 3 * BoardData.boardSize > kingIndex; index-=BoardData.boardSize){
            if(onFire(index, state.board)) return false;
          }
        default:
          return false;
      }
    } else{
      switch(state.currentPlayer){
        case 0:
          for(int index = kingIndex; index - 3 < kingIndex; index++){
            if(onFire(index, state.board)) return false;
          }
        case 1:
          for(int index = kingIndex; index - 3 * BoardData.boardSize < kingIndex; index+=BoardData.boardSize){
            if(onFire(index, state.board)) return false;
          }
        case 2:
          for(int index = kingIndex; index - 3 < kingIndex; index++){
            if(onFire(index, state.board)) return false;
          }
        case 3:
          for(int index = kingIndex; index - 3 * BoardData.boardSize < kingIndex; index+=BoardData.boardSize){
            if(onFire(index, state.board)) return false;
          }
        default:
          return false;
      }
    }
    return true;
  }


}




