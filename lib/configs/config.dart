import 'package:flutter/material.dart';

import '../models/chess_piece.dart';


abstract class GameConfig {
  static const defaultColors = {-1: Colors.grey, 0: Colors.yellow, 1: Colors.blue, 2: Colors.red, 3: Colors.green};
  static const defaultNames = {0: 'игрок 1', 1: 'игрок 2', 2: 'игрок 3', 3: 'игрок 4'};
  //for user interface
  final Map<int, MaterialColor> playerColors;
  final Map<int, String> playerNames;
  //for program logic
  final Command commands;
  final Promotion pawnPromotion;
  final int promotionCondition; //[3, 14], если 0 - edge with corners

  final bool onlyRegicide; //снимает все ограничения на маты, паты, проиграть можно лишь потеряв короля
  //эти настройки лишь при false
  final Stalemate oneOnOneStalemate; //когда остаётесь 1 на 1                                 --абсолютный приоритет
  final Stalemate aloneAmongAloneStalemate; // когда не 1 на 1 в бескомандном режиме          --одиночный режим
  final Stalemate commandOnOneStalemate; // когда пат у 1 без напарника из-за команды         --командный режим
  final Stalemate commandOnCommandStalemate; // когда пат у 1 с напарником                    --командный режим

  //wait
  final Timer timerType;
  final double timerTime;
  final TimeOut timeOut;//при цареубийстве всегда random

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
    this.onlyRegicide = false
  });

}

class OfflineConfig extends GameConfig{
  final bool turnPieces; //только для оффлайн
  OfflineConfig({
    super.playerColors,
    super.playerNames,
    super.commands,
    super.onlyRegicide,
    super.oneOnOneStalemate,
    super.aloneAmongAloneStalemate,
    super.commandOnOneStalemate,
    super.commandOnCommandStalemate,
    super.pawnPromotion,
    super.promotionCondition,
    super.timerType,
    super.timerTime,
    super.timeOut,
    this.turnPieces = false
  });
}
class OnlineConfig extends GameConfig {
  final bool publicAccess;
  final LoseConnection ifConnectionIsLost;

  OnlineConfig({
    super.playerColors,
    super.playerNames,
    super.commands,
    super.onlyRegicide,
    super.oneOnOneStalemate,
    super.aloneAmongAloneStalemate,
    super.commandOnOneStalemate,
    super.commandOnCommandStalemate,
    super.pawnPromotion,
    super.promotionCondition,
    super.timerType,
    super.timerTime,
    super.timeOut,
    this.publicAccess = true,
    this.ifConnectionIsLost = LoseConnection.wait,
  });

  factory OnlineConfig.fromMap(Map<String, dynamic> json) {
    // Парсим цвета: конвертируем String ключ в int (ID игрока)
    // и int значение в Color (HEX)
    final rawColors = json['playerColors'] as Map<String, dynamic>?;
    final Map<int, Color> parsedColors = rawColors?.map(
          (k, v) => MapEntry(int.parse(k), Color(v as int)),
    ) ?? GameConfig.defaultColors;

    // Парсим имена: конвертируем String ключ в int (ID игрока)
    final rawNames = json['playerNames'] as Map<String, dynamic>?;
    final Map<int, String> parsedNames = rawNames?.map(
          (k, v) => MapEntry(int.parse(k), v as String),
    ) ?? GameConfig.defaultNames;

    return OnlineConfig(
      // Специфичные для онлайн поля
      publicAccess: json['publicAccess'] ?? true,
      ifConnectionIsLost: LoseConnection.values.byName(json['ifConnectionIsLost'] ?? 'wait'),

      // Поля базового класса
      playerColors: parsedColors.cast<int, MaterialColor>(), // Если пока используешь MaterialColor
      playerNames: parsedNames,
      commands: Command.values.byName(json['commands'] ?? 'none'),
      pawnPromotion: Promotion.values.byName(json['pawnPromotion'] ?? 'queen'),
      promotionCondition: json['promotionCondition'] ?? 9,
      onlyRegicide: json['onlyRegicide'] ?? false,

      oneOnOneStalemate: Stalemate.values.byName(json['oneOnOneStalemate'] ?? 'draw'),
      aloneAmongAloneStalemate: Stalemate.values.byName(json['aloneAmongAloneStalemate'] ?? 'checkmate'),
      commandOnOneStalemate: Stalemate.values.byName(json['commandOnOneStalemate'] ?? 'draw'),
      commandOnCommandStalemate: Stalemate.values.byName(json['commandOnCommandStalemate'] ?? 'checkmate'),

      timerType: Timer.values.byName(json['timerType'] ?? 'none'),
      timerTime: (json['timerTime'] as num?)?.toDouble() ?? double.infinity,
      timeOut: TimeOut.values.byName(json['timeOut'] ?? 'randomMoves'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Сериализуем Map: ключи в JSON всегда строки
      'playerColors': playerColors.map((k, v) => MapEntry(k.toString(), v.value)),
      'playerNames': playerNames.map((k, v) => MapEntry(k.toString(), v)),

      'commands': commands.name,
      'pawnPromotion': pawnPromotion.name,
      'promotionCondition': promotionCondition,
      'onlyRegicide': onlyRegicide,

      'oneOnOneStalemate': oneOnOneStalemate.name,
      'aloneAmongAloneStalemate': aloneAmongAloneStalemate.name,
      'commandOnOneStalemate': commandOnOneStalemate.name,
      'commandOnCommandStalemate': commandOnCommandStalemate.name,

      'timerType': timerType.name,
      'timerTime': timerTime == double.infinity ? null : timerTime,
      'timeOut': timeOut.name,

      'publicAccess': publicAccess,
      'ifConnectionIsLost': ifConnectionIsLost.name,
    };
  }
}

enum Timer{none, perPlayer, perMove}
enum Stalemate{checkmate, draw, skipMove}
enum Promotion{queen, choice, random, randomWithPawn, none}
enum LoseConnection{checkmate, wait, randomMoves}
enum Command{none, oppositeSides, adjacentSides, random} // смежные стороны строго 0-1 и 2-3
enum TimeOut{checkmate, randomMoves}