// Оффлайн логика
import 'dart:math';

import 'package:chess_app/configs/config.dart';
import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/queen.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/board.dart';
import '../models/game.dart';
import '../models/king.dart';
import '../models/pawn.dart';
import '../models/rook.dart';

abstract class GameBaseNotifier extends StateNotifier<GameState> {
  GameBaseNotifier(super.initialBoard);

  bool makeMove(int fromIndex, int toIndex);
  bool checkmate(); //проверить на мат или невозможность ходить текущего игрока



  void onTileTapped(int index){
    if(state.selectedIndex != -1
        && state.availableMoves.contains(index)){
      if(makeMove(state.selectedIndex, index)){
        state = state.copyWith(selectedIndex: -1, availableMoves: [], currentPlayer: (state.currentPlayer + 1) % 4);
        _checkNextTurn();
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

  void _checkNextTurn(){
    //удаление enPassant если игрок жив
    if(state.alive[state.currentPlayer]){
      state = state.copyWith(enPassant: {state.currentPlayer : [-1, -1]});
      //проверка на мат если игрок жив
      if(checkmate()){
        List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
        for(int i = 0; i < board.length; i++){
          if(board[i] != null && board[i]!.owner == state.currentPlayer){
            board[i] = board[i]!.kill();
          }
        }
        state = state.copyWith(board: board, currentPlayerAlive: false, currentPlayer: (state.currentPlayer + 1) % 4);
      };
    }

    //проверка что игра продолжается
    if(state.alive.fold(0, (prev, alive) => prev + (alive ? 1 : 0)) > 1){
      //меняем активных пока не будет жив
      while(!state.alive[state.currentPlayer]){
        state = state.copyWith(currentPlayer: (state.currentPlayer + 1) % 4);
      }
    }

  }


  bool _onFire(int index, List<ChessPiece?> board){//мы не учитываем возможность рокировки ибо у нас же не должна попадать под обстрел и не учитываем мутки с en passant
    ChessPiece? piece = board[index];

    List<int> kings = List<int>.of(state.kings);
    if(piece == null) return false;

    for(int i = 0; i < board.length; i++){
      ChessPiece? enemyPiece = board[i];
      if(
      enemyPiece != null &&
          enemyPiece.owner != piece.owner &&
          enemyPiece.getPossibleMoves(i, state).contains(index)
      ) {
        return true;
      }
    }
    return false;
  }

  List<int> _truePossibleMoves(int index){
    ChessPiece? piece = state.board[index];
    List<ChessPiece?> draw = List<ChessPiece?>.of(state.board);
    List<int> kings = List<int>.of(state.kings);

    if(piece == null) return [];
    List<int> moves = piece.getPossibleMoves(index, state);

    for(int move in List<int>.of(moves)){ //перебираю каждый возможный ход    без учета enPassant и рокировки
      ChessPiece? temp = draw[move];
      draw[index] = null;
      draw[move] = piece;
      if(piece.type == 'king') kings[state.currentPlayer] = move;
      if(_onFire(state.kings[state.currentPlayer], draw)){
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
            if(_onFire(index, state.board)) return false;
          }
        case 1:
          for(int index = kingIndex; index + 3 * BoardData.boardSize > kingIndex; index-=BoardData.boardSize){
            if(_onFire(index, state.board)) return false;
          }
        case 2:
          for(int index = kingIndex; index + 3 > kingIndex; index--){
            if(_onFire(index, state.board)) return false;
          }
        case 3:
          for(int index = kingIndex; index + 3 * BoardData.boardSize > kingIndex; index-=BoardData.boardSize){
            if(_onFire(index, state.board)) return false;
          }
        default:
          return false;
      }
    } else{
      switch(state.currentPlayer){
        case 0:
          for(int index = kingIndex; index - 3 < kingIndex; index++){
            if(_onFire(index, state.board)) return false;
          }
        case 1:
          for(int index = kingIndex; index - 3 * BoardData.boardSize < kingIndex; index+=BoardData.boardSize){
            if(_onFire(index, state.board)) return false;
          }
        case 2:
          for(int index = kingIndex; index - 3 < kingIndex; index++){
            if(_onFire(index, state.board)) return false;
          }
        case 3:
          for(int index = kingIndex; index - 3 * BoardData.boardSize < kingIndex; index+=BoardData.boardSize){
            if(_onFire(index, state.board)) return false;
          }
        default:
          return false;
      }
    }
    return true;
  }


}



class OfflineGameNotifier extends GameBaseNotifier {
  OfflineGameNotifier(GameConfig config) : super(GameState.initial(config));

  @override
  bool makeMove(int fromIndex, int toIndex) {
    List<ChessPiece?> board = List<ChessPiece?>.from(state.board);
    final piece = board[fromIndex];
    if (piece == null) return false;

    if(board[toIndex] != null && board[toIndex]!.owner == state.currentPlayer && board[toIndex]!.type == 'rook') {
      _makeCastling(toIndex);
      return true;
    }

    board[fromIndex] = null;
    switch (piece.type) {
      case 'pawn':
        final pawn = piece as Pawn;
        board[toIndex] = pawn.copyWith(hasMoved: true);
        Map<int, List<int>> newEnPassant = Map<int, List<int>>.of(state.enPassant);
        int mayEnPassant = pawn.checkEnPassant(fromIndex, toIndex);
        newEnPassant[state.currentPlayer] = [mayEnPassant, (mayEnPassant == -1) ? -1 : toIndex];
        for(int key in state.enPassant.keys){
          if(state.enPassant[key]![0] == toIndex && board[state.enPassant[key]![1]]!.owner == key){ //en passant
            board[newEnPassant[key]![1]] = null; // убираем перехваченную пешку
            newEnPassant[key] = [-1, -1];
          }
        }
        if(pawn.isFinished(toIndex)){//если пешка финишировала
          board[toIndex] = Queen(owner: state.currentPlayer);
        }
        state = state.copyWith(board: board, enPassant: newEnPassant);
        break;
      case 'king':
        final king = piece as King;
        board[toIndex] = king.copyWith(hasMoved: true);
        int newIndexOfKing = toIndex;
        state = state.copyWith(board: board, newPlacementOfKing: newIndexOfKing);
        break;
      case 'rook':
        final rook = piece as Rook;
        board[toIndex] = rook.copyWith(hasMoved: true);
        state = state.copyWith(board: board);
        break;
      default:
        board[toIndex] = piece;
        state = state.copyWith(board: board);
    }
    return true;
  }

  @override
  bool checkmate() {
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    List<int> kings = List<int>.of(state.kings);
    //перебираем каждый возможный ход
    //если привел к шаху, откатываем назад и переходим к следующему
    //если не привел к шаху, возвращаем лож (выходим из перебора)
    for(int index = 0; index < board.length; index++){
      ChessPiece? piece = board[index];
      if(piece != null && piece.owner == state.currentPlayer){ //если это наша фигура
        for(int move in piece.getPossibleMoves(index, state)){ //перебираем каждый возможный ход
          ChessPiece? temp = board[move];
          board[index] = null;
          board[move] = piece;
          if(piece.type == 'king') kings[state.currentPlayer] = move;
          if(!_onFire(kings[state.currentPlayer], board)){
            return false;
          } else{
            board[move] = temp;
            board[index] = piece;
            kings[state.currentPlayer] = state.kings[state.currentPlayer];
          }
        }
      }
    }
    return true;
  }

  void _makeCastling(int rookIndex){
    int kingIndex = state.kings[state.currentPlayer];
    int newKingIndex = kingIndex;
    int newRookIndex = rookIndex;
    if(rookIndex < kingIndex){
      switch(state.currentPlayer){
        case 0:
          newRookIndex = rookIndex + 3;
          newKingIndex = kingIndex - 2;
        case 1:
          newRookIndex = rookIndex + 3 * BoardData.boardSize;
          newKingIndex = kingIndex - 2 * BoardData.boardSize;
        case 2:
          newRookIndex = rookIndex + 2;
          newKingIndex = kingIndex - 2;
        case 3:
          newRookIndex = rookIndex + 2 * BoardData.boardSize;
          newKingIndex = kingIndex - 2 * BoardData.boardSize;
      }
    } else{
      switch(state.currentPlayer){
        case 0:
          newRookIndex = rookIndex - 2;
          newKingIndex = kingIndex + 2;
        case 1:
          newRookIndex = rookIndex - 2 * BoardData.boardSize;
          newKingIndex = kingIndex + 2 * BoardData.boardSize;
        case 2:
          newRookIndex = rookIndex - 3;
          newKingIndex = kingIndex + 2;
        case 3:
          newRookIndex = rookIndex - 3 * BoardData.boardSize;
          newKingIndex = kingIndex + 2 * BoardData.boardSize;
      }
    }
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    board[newRookIndex] = (board[rookIndex] as Rook).copyWith(hasMoved: true);
    board[newKingIndex] = (board[kingIndex] as King).copyWith(hasMoved: true);
    state = state.copyWith(board: board, newPlacementOfKing: newKingIndex);
  }
}

// Онлайн логика
class OnlineGameNotifier extends GameBaseNotifier {
  OnlineGameNotifier(GameConfig config) : super(GameState.initial(config));

  @override
  bool makeMove(int fromIndex, int toIndex) {
    // TODO: implement makeMove
    return false;
  }

  @override
  bool checkmate() {
    // TODO: implement checkmate
    throw UnimplementedError();
  }



// final SocketClient socket;
// @override
// void makeMove(Move move) {
//   socket.sendMove(move); // Отправляем на Spring Boot
//   // Состояние обновится, когда придет ответ от сервера
// }


//то что ббыло раньше



  // StreamSubscription<String>? _gameSubscription;
  //
  // final WebSocketService _wbService = WebSocketService();
  //
  //
  // GameController() : super(GameState.initial()) {
  //   _listenToWebSocket();
  // }
  //
  // void _listenToWebSocket(){
  //   _gameSubscription = _wbService.gameStream.listen(
  //           (message){
  //         _handleIncomingMessage(message);
  //       },
  //       onError: (error){
  //         print('WebSocket Error: $error');
  //       },
  //       onDone: (){
  //         print('WebSocket Connection closed.');
  //       }
  //   );
  // }
  //
  // void _handleIncomingMessage(String message){
  //
  // }
  //
  //
  // void onTileTapped(int index){
  //
  //   if(state._selectedIndex != -1
  //       && state._availableMoves.contains(index)){
  //     _makeMove(state._selectedIndex, index);
  //     state._selectedIndex = -1;
  //     state._availableMoves = [];
  //     state = sta
  //     return;
  //   }
  //
  //   if(_selectedIndex == index || BoardData.corners.contains(index)){
  //     _selectedIndex = -1;
  //     _availableMoves = [];
  //   }
  //   else if (_board[index] != null){
  //     _selectedIndex = index;
  //     _availableMoves = _board[index]!.getPossibleMoves(index, _board);
  //   } else {
  //     _selectedIndex = -1;
  //     _availableMoves = [];
  //   }
  //   notifyListeners();
  // }
  //
  // void _makeMove(int fromIndex, int toIndex){
  //   final piece = _board[fromIndex];
  //   if (piece==null) return;
  //
  //   _board[fromIndex] = null;
  //   switch(piece.type){
  //     case 'Pawn':
  //       final pawn = piece as Pawn;
  //       _board[toIndex] = pawn.copyWith(hasMoved: true);
  //       break;
  //     case 'King':
  //       final king = piece as King;
  //       _board[toIndex] = king.copyWith(hasMoved: true);
  //       break;
  //     case 'Rook':
  //       final rook = piece as Rook;
  //       _board[toIndex] = rook.copyWith(hasMoved: true);
  //     default:
  //       _board[toIndex] = piece;
  //   }
}