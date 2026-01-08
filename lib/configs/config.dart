import 'package:flutter/material.dart';

import '../models/chess_piece.dart';

class GameConfig {
  final Map<int, MaterialColor> playerColors;

  GameConfig({required this.playerColors});
}