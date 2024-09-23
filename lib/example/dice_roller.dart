import 'dart:math';

import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';

class DiceRoller extends Game {
  @override
  String get name => "Dice Roller";

  @override
  int get requiredPlayers => 2;

  @override
  int get playerLimit => 4;

  @override
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    return {"currentPlayer": 0, "roll": -1};
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    if (players.indexOf(player) != gameState["currentPlayer"]) {
      return const NotPlayerTurn();
    }
    return const CheckResultSuccess();
  }

  @override
  void processEvent(
      {required GameEvent event,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    gameState["roll"] = random.nextInt(6) + 1;
    gameState["currentPlayer"] =
        (gameState["currentPlayer"] + 1) % players.length;
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    if (gameState["currentPlayer"] >= players.length) {
      gameState["currentPlayer"] = 0;
    }
  }

  @override
  Map<String, dynamic>? checkGameEnd(
      {required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    return null;
  }
}
