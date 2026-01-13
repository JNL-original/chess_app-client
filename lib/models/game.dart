import 'dart:math';

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
  final Command commands;
  final GameStatus? status;
  final int promotionPawn;
  final int? myPlayerIndex;//-1 это режим оффлайн, null зритель
  final int turn; //чтобы сверятся с сервером и переполучить данные в случае несоответствия


  final GameConfig config;

  const GameState({
    required this.board,
    required this.selectedIndex,
    required this.availableMoves,
    required this.currentPlayer,
    required this.kings,
    required this.alive,
    required this.enPassant,
    required this.commands,
    required this.status,
    required this.promotionPawn,
    required this.config,
    required this.myPlayerIndex,
    required this.turn
  });

  factory GameState.initial(GameConfig config){
    List<ChessPiece?> board =  BoardData.initializePieces(config);
    Command commands;
    if(config.commands == Command.random){
      int intValue = Random().nextInt(2);
      if(intValue == 0) {
        commands = Command.oppositeSides;
      }
      else {
        commands = Command.adjacentSides;
      }
    }
    else {
      commands = config.commands;
    }

    return GameState(
      board: board,
      selectedIndex: -1,
      availableMoves: [],
      currentPlayer: 0,
      kings: _initializedKings(board),
      alive: [true, true, true, true],
      enPassant: {0: [-1, -1], 1: [-1, -1], 2: [-1, -1], 3: [-1, -1],},
      commands: commands,
      status: GameStatus.active,
      promotionPawn: -1,
      config: config,
      myPlayerIndex: -1,
      turn: 0
    );
  }

  GameState copyWith({List<ChessPiece?>? board, int? selectedIndex, List<int>? availableMoves, int? killPlayer,
    int? currentPlayer, int? newPlacementOfKing, List<int>? kings, bool? currentPlayerAlive, Map<int, List<int>>? enPassant,
    GameStatus? status, int? promotionPawn, int? myPlayerIndex, int? turn}){
    return GameState(
      board: board ?? this.board,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      availableMoves: availableMoves ?? this.availableMoves,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      kings: _updateKing(newPlacementOfKing, kings),
      alive: _updateAlive(currentPlayerAlive, killPlayer),
      enPassant: _updateEnPassant(enPassant),
      commands: commands,
      status: status ?? this.status,
      promotionPawn: promotionPawn ?? this.promotionPawn,
      config: config,
      myPlayerIndex: myPlayerIndex ?? this.myPlayerIndex,
      turn: turn ?? this.turn
    );
  }

  bool isEnemies(int firstPlayer, int secondPlayer){
    if(firstPlayer == secondPlayer || firstPlayer < 0 || secondPlayer < 0) return false;
    switch(commands){
      case Command.none:
        return true;
      case Command.oppositeSides:
        return firstPlayer % 2 != secondPlayer % 2;
      case Command.adjacentSides:
        return firstPlayer % 2 == secondPlayer % 2;
      default:
        return false;
    }
  }

  Stalemate ifStalemate(){//мы уже учитываем, что на момент проверки игра еще продолжалась
    if(alive.fold(0, (prev, el) => prev + (el ? 1 : 0)) == 2) { //когда остаётесь 1 на 1
      return config.oneOnOneStalemate;
    }
    if(commands == Command.none) return config.aloneAmongAloneStalemate; //когда нет команд, и еще не 1 на 1
    //мы уже точно знаем что осталось 3+ игроков и у нас командный режим
    if(alive[(currentPlayer + 1) % 4] && !isEnemies(currentPlayer, (currentPlayer + 1) % 4) ||//если есть живой союзник у проверяемого игрока
        alive[(currentPlayer + 2) % 4] && !isEnemies(currentPlayer, (currentPlayer + 2) % 4) ||
        alive[(currentPlayer + 3) % 4] && !isEnemies(currentPlayer, (currentPlayer + 3) % 4)){
      return config.commandOnCommandStalemate;
    }
    return config.commandOnOneStalemate;
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

  List<int> _updateKing(int? placementOfKing, List<int>? updateKings){
    if(updateKings != null) return updateKings;
    if(placementOfKing == null){
      return kings;
    }
    List<int> newKings = List<int>.of(kings);
    newKings[currentPlayer] = placementOfKing;
    return newKings;
  }

  List<bool> _updateAlive(bool? currentPlayerAlive, int? killPlayer) {
    List<bool> newAlive = List<bool>.of(alive);
    if(currentPlayerAlive != null) newAlive[currentPlayer] = currentPlayerAlive;
    if(killPlayer != null) newAlive[killPlayer] = false;
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


  factory GameState.fromMap(Map<String, dynamic> data) {
    // 1. Парсим доску. Важно сохранить null!
    final List<dynamic> rawBoard = data['board'];
    final List<ChessPiece?> parsedBoard = rawBoard.map((item) {
      if (item == null) return null;
      return ChessPiece.fromMap(item as Map<String, dynamic>);
    }).toList();

    // 2. Парсим enPassant. В JSON ключи всегда строки, переводим обратно в int
    final rawEnPassant = data['enPassant'] as Map<String, dynamic>;
    final Map<int, List<int>> parsedEnPassant = rawEnPassant.map(
          (key, value) => MapEntry(
          int.parse(key),
          (value as List).map((v) => v as int).toList()
      ),
    );

    return GameState(
      board: parsedBoard,
      selectedIndex: data['selectedIndex'] ?? -1,
      availableMoves: (data['availableMoves'] as List? ?? []).map((e) => e as int).toList(),
      currentPlayer: data['currentPlayer'] ?? 0,
      kings: (data['kings'] as List).map((e) => e as int).toList(),
      alive: (data['alive'] as List).map((e) => e as bool).toList(),
      enPassant: parsedEnPassant,
      commands: Command.values.byName(data['commands'] ?? 'none'),
      status: GameStatus.values.byName(data['status'] ?? 'active'),
      promotionPawn: data['promotionPawn'] ?? -1,
      myPlayerIndex: data['myPlayerIndex'],
      turn: data['turn'] ?? 0,
      config: OnlineConfig.fromMap(data['config'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'board': board.map((p) => p?.toMap()).toList(), // null сохранятся в списке автоматически
      'selectedIndex': selectedIndex,
      'availableMoves': availableMoves,
      'currentPlayer': currentPlayer,
      'kings': kings,
      'alive': alive,
      'enPassant': enPassant.map((k, v) => MapEntry(k.toString(), v)),
      'commands': commands.name,
      'status': status?.name,
      'promotionPawn': promotionPawn,
      'myPlayerIndex': myPlayerIndex,
      'turn': turn,
      'config': (config as OnlineConfig).toMap(),
    };
  }

}

enum GameStatus{active, over, waitingForPromotion, draw, lobby, connecting, waitResponse}