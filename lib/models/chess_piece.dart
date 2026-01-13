import 'package:chess_app/models/pawn.dart';
import 'package:chess_app/models/queen.dart';
import 'package:chess_app/models/rook.dart';

import 'bishop.dart';
import 'game.dart';
import 'king.dart';
import 'knight.dart';

abstract class ChessPiece {
  final int owner;
  final String type;

  const ChessPiece({
    required this.owner,
    required this.type,
  });

  List<int> getPossibleMoves(int currentIndex, GameState game);
  ChessPiece? kill();

  @override
  String toString() {
    return "$type (player ${owner + 1})";
  }

  factory ChessPiece.fromMap(Map<String, dynamic> map) {
    final owner = map['owner'] as int;
    final type = map['type'] as String;
    final hasMoved = map['hasMoved'] as bool? ?? false;

    // Здесь мы возвращаем конкретный подкласс в зависимости от типа
    switch (type) {
      case 'pawn': return Pawn(owner: owner, hasMoved: hasMoved);
      case 'king': return King(owner: owner, hasMoved: hasMoved);
      case 'rook': return Rook(owner: owner, hasMoved: hasMoved);
      case 'knight': return Knight(owner: owner);
      case 'bishop': return Bishop(owner: owner);
      case 'queen': return Queen(owner: owner);
      default: throw Exception("Unknown piece type: $type");
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'owner': owner,
      'type': type,
      // Добавь проверку на наличие поля hasMoved, если оно есть в подклассах
      'hasMoved': (this is Pawn || this is King || this is Rook) ? (this as dynamic).hasMoved : false,
    };
  }
}