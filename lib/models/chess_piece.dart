import 'dart:ui';

import 'package:flutter/material.dart';

import 'game.dart';

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
}