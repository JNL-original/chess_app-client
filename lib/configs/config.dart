import 'package:flutter/material.dart';

import '../models/chess_piece.dart';

abstract class GameConfig {
  //for user interface
  final Map<int, MaterialColor> playerColors;
  final Map<int, String> playerNames;

  //for program logic
  final Command commands;
  final Stalemate oneOnOneStalemate; //когда остаётесь 1 на 1                                 --абсолютный приоритет
  final Stalemate aloneAmongAloneStalemate; // когда не 1 на 1 в бескомандном режиме          --одиночный режим
  final Stalemate commandOnOneStalemate; // когда пат у 1 без напарника из-за команды         --командный режим
  final Stalemate commandOnCommandStalemate; // когда пат у 1 с напарником                    --командный режим
  final Promotion pawnPromotion;
  final int promotionCondition; //[3, 14], если 0 - edge with corners

  //wait
  final Timer timerType;
  final double timerTime;
  final TimeOut timeOut;

  GameConfig({
    this.playerColors = const {-1 : Colors.grey, 0 : Colors.yellow, 1 : Colors.blue, 2 : Colors.red, 3 : Colors.green},
    this.playerNames = const {0:'игрок 1', 1:'игрок 2', 2:'игрок 3', 3:'игрок 4'},
    this.commands = Command.none,
    this.oneOnOneStalemate = Stalemate.draw,
    this.aloneAmongAloneStalemate = Stalemate.checkmate,
    this.commandOnOneStalemate = Stalemate.draw,
    this.commandOnCommandStalemate = Stalemate.checkmate,
    this.pawnPromotion = Promotion.queen,
    this.promotionCondition = 9,
    this.timerType = Timer.none,
    this.timerTime = double.infinity,
    this.timeOut = TimeOut.randomMoves,
  });

}

class OfflineConfig extends GameConfig{
  final bool turnPieces; //только для оффлайн
  OfflineConfig({
    super.playerColors = const {-1 : Colors.grey, 0 : Colors.yellow, 1 : Colors.blue, 2 : Colors.red, 3 : Colors.green},
    super.playerNames = const {0:'игрок 1', 1:'игрок 2', 2:'игрок 3', 3:'игрок 4'},
    this.turnPieces = false,
    super.commands = Command.none,
    super.oneOnOneStalemate = Stalemate.draw,
    super.aloneAmongAloneStalemate = Stalemate.checkmate,
    super.commandOnOneStalemate = Stalemate.draw,
    super.commandOnCommandStalemate = Stalemate.checkmate,
    super.pawnPromotion = Promotion.queen,
    super.promotionCondition = 9,
    super.timerType = Timer.none,
    super.timerTime = double.infinity,
    super.timeOut = TimeOut.randomMoves
  });
}
class OnlineConfig extends GameConfig{
  final bool publicAccess;
  final LoseConnection ifConnectionIsLost;    //только для онлайн

  OnlineConfig({
    super.playerColors = const {-1 : Colors.grey, 0 : Colors.yellow, 1 : Colors.blue, 2 : Colors.red, 3 : Colors.green},
    super.playerNames = const {0:'игрок 1', 1:'игрок 2', 2:'игрок 3', 3:'игрок 4'},
    super.commands = Command.none,
    super.oneOnOneStalemate = Stalemate.draw,
    super.aloneAmongAloneStalemate = Stalemate.checkmate,
    super.commandOnOneStalemate = Stalemate.draw,
    super.commandOnCommandStalemate = Stalemate.checkmate,
    super.pawnPromotion = Promotion.queen,
    super.promotionCondition = 9,
    super.timerType = Timer.none,
    super.timerTime = double.infinity,
    super.timeOut = TimeOut.randomMoves,
    this.publicAccess = true,
    this.ifConnectionIsLost = LoseConnection.wait
  });
}

enum Timer{none, perPlayer, perMove}
enum Stalemate{checkmate, draw, skipMove}
enum Promotion{queen, choice, random, randomWithPawn, none}
enum LoseConnection{checkmate, wait, randomMoves}
enum Command{none, oppositeSides, adjacentSides, random} // смежные стороны строго 0-1 и 2-3
enum TimeOut{checkmate, randomMoves}