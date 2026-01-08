import '../configs/config.dart';
import 'board.dart';
import 'chess_piece.dart';

class GameState {
  final List<ChessPiece?> board;
  final int selectedIndex;
  final List<int> availableMoves;
  final int currentPlayer;
  final List<int> kings;
  final List<bool> alive;
  final Map<int, List<int>> enPassant; //player : [enPassant, pawn]

  const GameState({
    required this.board,
    required this.selectedIndex,
    required this.availableMoves,
    required this.currentPlayer,
    required this.kings,
    required this.alive,
    required this.enPassant
  });

  factory GameState.initial(GameConfig config){
    List<ChessPiece?> board =  BoardData.initializePieces(config);
    return GameState(
      board: board,
      selectedIndex: -1,
      availableMoves: [],
      currentPlayer: 0,
      kings: _initializedKings(board),
      alive: [true, true, true, true],
      enPassant: {0: [-1, -1], 1: [-1, -1], 2: [-1, -1], 3: [-1, -1]}
    );
  }

  GameState copyWith({List<ChessPiece?>? board, int? selectedIndex, List<int>? availableMoves, int? currentPlayer, int? newPlacementOfKing, bool? currentPlayerAlive, Map<int, List<int>>? enPassant}){
    return GameState(
      board: board ?? this.board,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      availableMoves: availableMoves ?? this.availableMoves,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      kings: _updateKing(newPlacementOfKing),
      alive: _updateAlive(currentPlayerAlive),
      enPassant: _updateEnPassant(enPassant)
    );
  }

  static List<int> _initializedKings(List<ChessPiece?> board){
    List<int> kings = List<int>.filled(4, -1);
    for(int index = 0; index < board.length; index++){
      if(board[index] != null && board[index]!.type == 'king' && board[index]!.owner >= 0){
        kings[board[index]!.owner] = index;
      }
    }
    return kings;
  }

  List<int> _updateKing(int? placementOfKing){
    if(placementOfKing == null){
      return kings;
    }
    List<int> newKings = List<int>.of(kings);
    newKings[currentPlayer] = placementOfKing;
    return newKings;
  }

  List<bool> _updateAlive(bool? currentPlayerAlive) {
    if(currentPlayerAlive == null){
      return alive;
    }
    List<bool> newAlive = List<bool>.of(alive);
    newAlive[currentPlayer] = currentPlayerAlive;
    return newAlive;
  }

  Map<int, List<int>> _updateEnPassant(Map<int, List<int>>? enPassant) {
    if(enPassant == null){
      return this.enPassant;
    }
    Map<int, List<int>> newEnPassant = Map<int, List<int>>.of(this.enPassant);
    for(int key in enPassant.keys){
      newEnPassant[key] = enPassant[key]!;
    }
    return newEnPassant;
  }

}