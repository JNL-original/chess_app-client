
// Онлайн логика
import 'dart:async';
import 'dart:convert';
import 'package:chess_app/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../configs/config.dart';
import '../models/chess_piece.dart';
import '../models/game.dart';
import '../models/pawn.dart';
import '../models/rook.dart';
import 'base_notifier.dart';

part 'online_controller.g.dart';

@riverpod
class OnlineGame extends _$OnlineGame with GameBaseNotifier{
  late String _roomId;
  late WebSocketChannel channel;

  @override
  GameState build(String roomId) {
    _roomId = roomId;
    channel = ref.watch(webSocketProvider(_roomId));

    final subscription = _subscript();
    ref.onDispose(() => subscription.cancel());

    channel.sink.add(jsonEncode({
      'type': 'connect'
    }));

    return GameState.initial(OnlineConfig()).copyWith(status: GameStatus.connecting);
  }

  StreamSubscription<dynamic> _subscript() {
    return channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'sync') {
        state = GameState.fromMap(data['data']);
      }
      if(data['turn'] != state.turn + 1) {channel.sink.add(jsonEncode({'type': 'connect'}));}
      else{
        switch(data['type']){
          case 'move':
            _handleMove(data);
          case 'castling':
            _handleCastling(data);
          case 'death':
            _handleDeath(data);
          case 'promotion':
            _handlePromotion(data);
          case 'changeStatus':
            _handleChangeStatus(data);
          default:
            channel.sink.add(jsonEncode({'type': 'connect'}));
        }
      }
    },
      onError: (err) {
        print("WS Error: $err");
      },
      onDone: () => print("Connection closed"),);
  }

  @override
  bool makeMove(int fromIndex, int toIndex) {
    channel.sink.add(jsonEncode({
      'type': 'move',
      'from': fromIndex,
      'to': toIndex,
    }));
    return true;
  }

  @override
  Stalemate? checkmate() {
    throw UnimplementedError();//никогда не выполнится
  }

  @override
  void continueGameAfterPromotion(ChessPiece piece) {
    channel.sink.add(jsonEncode({
      'type': 'promotion',
      'who': piece.toMap(),
    }));
  }

  @override
  void nextPlayer() {} //переход к следующему игроку и его проверку реализует сервер

  void _handleMove(Map<String, dynamic> data){
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    board[data['from']] = null;
    board[data['to']] = ChessPiece.fromMap(data['who']);
    final rawEnPassant = data['enPassant'] as Map<String, dynamic>;
    final parsedEnPassant = rawEnPassant.map(
            (k, v) => MapEntry(int.parse(k), List<int>.from(v))
    );
    state = state.copyWith(
      board: board,
      enPassant: parsedEnPassant,
      currentPlayer: data['currentPlayer'],
      kings: data['kings'],
      status: data['status'],
      turn: data['turn'],
      availableMoves: [],
      selectedIndex: -1,
      promotionPawn: data['promotionPawn']
    );
  }
  void _handleCastling(Map<String, dynamic> data){
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    board[data['kingFrom']] = null;
    board[data['kingTo']] = ChessPiece.fromMap(data['king']);
    board[data['rookFrom']] = null;
    board[data['rookTo']] = ChessPiece.fromMap(data['rook']);
    final rawEnPassant = data['enPassant'] as Map<String, dynamic>;
    final parsedEnPassant = rawEnPassant.map(
            (k, v) => MapEntry(int.parse(k), List<int>.from(v))
    );
    state = state.copyWith(
      board: board,
      enPassant: parsedEnPassant,
      currentPlayer: data['currentPlayer'],
      kings: data['kings'],
      status: data['status'],
      turn: data['turn'],
      availableMoves: [],
      selectedIndex: -1
    );
  }
  void _handleDeath(Map<String, dynamic> data){
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    for(int i = 0; i < board.length; i++){
      if(board[i] != null && board[i]!.owner == data['dead']){
        board[i] = board[i]!.kill();
      }
    }
    state = state.copyWith(
      board: board,
      currentPlayer: data['currentPlayer'],
      status: data['status'],
      turn: data['turn'],
      availableMoves: [],
      selectedIndex: -1
    );
  }
  void _handleChangeStatus(Map<String, dynamic> data){
    state = state.copyWith(
      status: data['status'],
      turn: data['turn']
    );
  }
  void _handlePromotion(Map<String, dynamic> data){
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    board[data['index']] = ChessPiece.fromMap(data['who']);
    state = state.copyWith(
      board: board,
      currentPlayer: data['currentPlayer'],
      status: data['status'],
      turn: data['turn'],
      availableMoves: [],
      selectedIndex: -1,
      promotionPawn: -1
    );
  }
}