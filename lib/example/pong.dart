import 'dart:math';
import 'dart:ui';

import 'package:either_dart/either.dart';
import 'package:fire_game_infra/fire_game_infra.dart';

class PongGameState extends GameState {
  Map<Player, int> scores;
  Player? lastHitter;
  Map<Player, Offset> positions;
  Map<Player, Offset> directions;

  PongGameState(
      {required this.scores,
      this.lastHitter,
      required this.positions,
      required this.directions});
}

class Pong extends Game {
  @override
  String get name => "Ping Pong";

  @override
  int get requiredPlayers => 2;

  @override
  int get playerLimit => 2;

  @override
  GameState getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    return PongGameState(
      scores: {for (var p in players) p: 0},
      lastHitter: null,
      positions: {for (var p in players) p: Offset.zero},
      directions: {for (var p in players) p: Offset.zero},
    );
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required covariant PongGameState gameState,
      required List<Player> players,
      required Player host}) {
    return const CheckResultSuccess();
  }

  Player getOpposite(Player player, List<Player> players) {
    if (players.length != 2) throw Exception("Not 2 players");
    return players.first == player ? players.last : players.first;
  }

  @override
  Either<CheckResultFailure, dynamic> getGameResponse(
      {required Map<String, dynamic> request,
      required Player player,
      required covariant PongGameState gameState,
      required List<Player> players,
      required Player host}) {
    return Right(getOpposite(player, players));
  }

  @override
  void processEvent(
      {required GameEvent event,
      required covariant PongGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    switch (event.payload["type"]) {
      case "hit":
        gameState.positions[event.author] =
            Offset(event.payload["px"], event.payload["py"]);
        gameState.directions[event.author] =
            Offset(event.payload["dx"], event.payload["dy"]);
        gameState.lastHitter = event.author;
        break;
      case "miss":
        gameState.scores[getOpposite(event.author, players)] =
            gameState.scores[getOpposite(event.author, players)]! + 1;
        gameState.lastHitter = event.author;
        break;
    }
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required covariant PongGameState gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {}

  @override
  Map<String, dynamic>? checkGameEnd(
      {required covariant PongGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    if (gameState.scores[players.first]! >= 7) {
      return {"draw": false, "winnerName": players.first.name};
    }
    if (gameState.scores[players.last]! >= 7) {
      return {"draw": false, "winnerName": players.last.name};
    }
    return null;
  }
}
