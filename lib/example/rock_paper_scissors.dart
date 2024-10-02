import 'dart:math';

import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';

enum RockPaperScissorsChoice {
  rock(key: "rock", icon: "🪨"),
  paper(key: "paper", icon: "📄"),
  scissors(key: "scissors", icon: "✂️");

  final String key;
  final String icon;

  const RockPaperScissorsChoice({required this.key, required this.icon});

  RockPaperScissorsChoice get beats {
    const values = RockPaperScissorsChoice.values;
    var index = values.indexOf(this);
    if (index == 0) index = values.length;
    return values[index - 1];
  }

  static RockPaperScissorsChoice fromKey(String key) =>
      RockPaperScissorsChoice.values.where((e) => e.key == key).first;
}

class RockPaperScissors extends Game {
  @override
  String get name => "Rock Paper Scissors";

  @override
  int get requiredPlayers => 2;

  @override
  int get playerLimit => 2;

  @override
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    return {"choices": List<RockPaperScissorsChoice?>.filled(2, null)};
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    var index = players.indexOf(player);
    final List<RockPaperScissorsChoice?> choices = gameState["choices"];
    if (index < 0 || index >= choices.length) return const OutOfBounds();
    if (choices[index] != null) {
      return const CheckResultFailure("You already made your choice.");
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
    var index = players.indexOf(event.author);
    final List<RockPaperScissorsChoice?> choices = gameState["choices"];
    choices[index] = RockPaperScissorsChoice.fromKey(event.payload["choice"]);
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {}

  @override
  Map<String, dynamic>? checkGameEnd(
      {required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    final List<RockPaperScissorsChoice?> choices = gameState["choices"];
    if (choices.any((e) => e == null)) return null;
    if (choices[0] == choices[1]) return {"draw": true};
    return {
      "draw": false,
      "winnerName":
          choices[0]?.beats == choices[1] ? players[0].name : players[1].name
    };
  }
}
