import 'dart:math';

import 'package:chess_app/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../configs/config.dart';
import '../models/bishop.dart';
import '../models/board.dart';
import '../models/chess_piece.dart';
import '../models/game.dart';
import '../models/king.dart';
import '../models/knight.dart';
import '../models/pawn.dart';
import '../models/queen.dart';
import '../models/rook.dart';
import 'base_notifier.dart';

part 'offline_controller.g.dart';

@riverpod
class OfflineGame extends _$OfflineGame with GameBaseNotifier {

  @override
  bool makeMove(int fromIndex, int toIndex) {
    List<ChessPiece?> board = List<ChessPiece?>.from(state.board);
    final piece = board[fromIndex];
    if (piece == null) return false;

    if(board[toIndex] != null && board[toIndex]!.owner == state.currentPlayer && board[toIndex]!.type == 'rook') {
      _makeCastling(toIndex);
      return true;
    }
    if(board[toIndex] != null && board[toIndex]!.type == 'king'){
      int killPlayer = board[toIndex]!.owner;
      for(int i = 0; i < board.length; i++){
        if(board[i] != null && board[i]!.owner == killPlayer){
          board[i] = board[i]!.kill();
        }
      }
      state = state.copyWith(board: board, killPlayer: killPlayer);
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
        if(state.config.pawnPromotion != Promotion.none && pawn.isFinished(toIndex, state.config.promotionCondition)){//если пешка финишировала
          switch(state.config.pawnPromotion){
            case Promotion.queen:
              board[toIndex] = Queen(owner: state.currentPlayer);
            case Promotion.choice:
              board[toIndex] = Pawn(owner: state.currentPlayer, hasMoved: true);
              state = state = state.copyWith(board: board, enPassant: newEnPassant, status: GameStatus.waitingForPromotion, promotionPawn: toIndex);
              return true;
            case Promotion.random:
              int intValue = Random().nextInt(4);
              switch(intValue){
                case 0:
                  board[toIndex] = Queen(owner: state.currentPlayer);
                case 1:
                  board[toIndex] = Rook(owner: state.currentPlayer, hasMoved: true);
                case 2:
                  board[toIndex] = Knight(owner: state.currentPlayer);
                case 3:
                  board[toIndex] = Bishop(owner: state.currentPlayer);
              }
            case Promotion.randomWithPawn:
              int intValue = Random().nextInt(5);
              switch(intValue){
                case 0:
                  board[toIndex] = Queen(owner: state.currentPlayer);
                case 1:
                  board[toIndex] = Rook(owner: state.currentPlayer, hasMoved: true);
                case 2:
                  board[toIndex] = Knight(owner: state.currentPlayer);
                case 3:
                  board[toIndex] = Bishop(owner: state.currentPlayer);
                case 4:
                  board[toIndex] = Pawn(owner: state.currentPlayer, hasMoved: true);
              }
            case Promotion.none:
              board[toIndex] = Pawn(owner: state.currentPlayer, hasMoved: true);
          }
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
  Stalemate? checkmate() {
    //проверка для режима цареубийство
    if(state.config.onlyRegicide){
      for(int index = 0; index < state.board.length; index++){
        if(state.board[index]!=null && state.board[index]!.owner == state.currentPlayer && state.board[index]!.getPossibleMoves(index, state).isNotEmpty){
          return null;
        }
      }
      return Stalemate.skipMove;
    }
    //проверка для остального режима
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
          if(!onFire(kings[state.currentPlayer], board)){
            return null;
          } else{
            board[move] = temp;
            board[index] = piece;
            kings[state.currentPlayer] = state.kings[state.currentPlayer];
          }
        }
      }
    }
    //проверка на пат
    if(onFire(kings[state.currentPlayer], board)){//проверка на мат
      return Stalemate.checkmate;
    }
    else{
      return state.ifStalemate();
    }
  }

  @override
  void continueGameAfterPromotion(ChessPiece piece){
    //сменить статус, закончить ход, убрать индекс превращаемой пешки
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    switch(piece.type){
      case 'pawn':
        board[state.promotionPawn] = Pawn(owner: state.currentPlayer, hasMoved: true);
      case 'rook':
        board[state.promotionPawn] = Rook(owner: state.currentPlayer, hasMoved: true);
      default:
        board[state.promotionPawn] = piece;
    }
    state = state.copyWith(board: board, selectedIndex: -1, availableMoves: [], status: GameStatus.active, promotionPawn: -1);
    nextPlayer();
  }



  @override
  void nextPlayer() {
    state = state.copyWith(currentPlayer: (state.currentPlayer + 1) % 4);
    _checkNextTurn();
  }
  void _checkNextTurn(){
    bool wasChange = false; //было ли доп изменение текущего игрока
    //удаление enPassant если игрок жив
    if(state.alive[state.currentPlayer]!){
      state = state.copyWith(enPassant: {state.currentPlayer : [-1, -1]});
      //проверка на мат если игрок жив
      switch(checkmate()){
        case null:
          break;
        case Stalemate.checkmate:
          List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
          for(int i = 0; i < board.length; i++){
            if(board[i] != null && board[i]!.owner == state.currentPlayer){
              board[i] = board[i]!.kill();
            }
          }
          state = state.copyWith(board: board, currentPlayerAlive: false, currentPlayer: (state.currentPlayer + 1) % 4);
          wasChange = true;
          break;
        case Stalemate.draw:
          state = state.copyWith(status: GameStatus.draw);
        case Stalemate.skipMove:
          state = state.copyWith(currentPlayer: (state.currentPlayer + 1) % 4);
          wasChange = true;
      }
    }

    //проверка что игра продолжается
    if(!_gameIsActive()) state = state.copyWith(status: GameStatus.over);
    if(state.status == GameStatus.active){
      //меняем активных пока не будет жив
      while(!state.alive[state.currentPlayer]!){
        state = state.copyWith(currentPlayer: (state.currentPlayer + 1) % 4);
        wasChange = true;
      }
      if(wasChange) _checkNextTurn();// рекурсивно вызываем проверку следующего активного игрока
    }

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
    board[rookIndex] = null;
    board[kingIndex] = null;
    state = state.copyWith(board: board, newPlacementOfKing: newKingIndex);
  }


  bool _gameIsActive(){
    int activePlayer = state.alive.indexOf(true);
    if(activePlayer == 3 || activePlayer == -1) return false;
    switch(state.config.commands){
      case Command.none:
        return state.alive[(activePlayer + 1) % 4]! || state.alive[(activePlayer + 2) % 4]! || state.alive[(activePlayer + 3) % 4]!;
      case Command.oppositeSides:
        return state.alive[(activePlayer + 1) % 4]! || state.alive[(activePlayer + 3) % 4]!;
      case Command.adjacentSides:
        if(activePlayer > 1) return false;
        return state.alive[2]! || state.alive[3]!;
      default:
        return false;
    }
  }

  @override
  GameState build() {
    final config = ref.watch(offlineConfigControlProvider);
    return GameState.initial(config);
  }
}