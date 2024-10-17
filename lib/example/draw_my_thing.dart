import 'dart:math';
import 'dart:ui';

import 'package:either_dart/either.dart';
import 'package:flutter_fire_engine/example/draw_my_thing_words.dart';
import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:collection/collection.dart';
import 'package:pair/pair.dart';

class DrawMyThing extends Game {
  @override
  String get name => "Draw My Thing";

  @override
  int get requiredPlayers => 3;

  @override
  int get playerLimit => 6;

  int getRoundCount(int playerCount) {
    int maxPerPlayer = 3;
    int maxCount = 10;
    int count = 0;
    for (var i = 0; i < maxPerPlayer; i++) {
      for (var j = 0; j < playerCount; j++) {
        count++;
      }
      if (count >= maxCount) break;
    }
    return count;
  }

  List<String> getWordOptions() {
    return List.generate(3, (_) => words[Random().nextInt(words.length)]);
  }

  @override
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    return {
      "selectingWord": true,
      "wordOptions": getWordOptions(),
      "currentWord": "",
      "currentPlayer": 0,
      "currentDrawing": <List<Offset>>[],
      "currentGuesses": <Pair<Player, String>>[],
      "scores": {for (var p in players) p: 0},
      "currentScorers": <Player>[],
      "roundCount": 0,
    };
  }

  @override
  Either<CheckResultFailure, dynamic> getGameResponse(
      {required Map<String, dynamic> request,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    switch (request["type"]) {
      case "serializeLine":
        final line = request["line"] as List<Offset>;
        return Right(line
            .map((point) => {"x": point.dx.toInt(), "y": point.dy.toInt()})
            .toList());
      case "isCurrentPlayer":
        return Right(players.indexOf(player) == gameState["currentPlayer"]);
      case "getCurrentPlayer":
        return Right(players[gameState["currentPlayer"]]);
      case "timerLimit":
        return const Right(120);
      case "totalRoundCount":
        return Right(getRoundCount(players.length));
    }
    return super.getGameResponse(
        request: request,
        player: player,
        gameState: gameState,
        players: players,
        host: host);
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    switch (event["type"]) {
      case "selectWord":
        if (!gameState["selectingWord"]) {
          return const CheckResultFailure("Word has already been selected");
        }
        if (players.indexOf(player) != gameState["currentPlayer"]) {
          return const CheckResultFailure("Not player turn");
        }
        break;
      case "draw":
      case "undo":
      case "turnChange":
        if (gameState["selectingWord"]) {
          return const CheckResultFailure("Word is being selected");
        }
        if (players.indexOf(player) != gameState["currentPlayer"]) {
          return const CheckResultFailure("Not player turn");
        }
        break;
      case "guess":
        if (gameState["selectingWord"]) {
          return const CheckResultFailure("Word is being selected");
        }
        if (players.indexOf(player) == gameState["currentPlayer"]) {
          return const CheckResultFailure("Drawer cannot guess");
        }
        if ((gameState["currentScorers"] as List<Player>).contains(player)) {
          return const CheckResultFailure("Already guessed successfully");
        }
        break;
      default:
        return const CheckResultFailure("Unspecified event type");
    }
    return const CheckResultSuccess();
  }

  List<Offset> deserializeLine(List<dynamic> jsonLine) {
    return jsonLine
        .map((point) => Offset(point["x"].toDouble(), point["y"].toDouble()))
        .toList();
  }

  @override
  void processEvent(
      {required GameEvent event,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    switch (event.payload["type"]) {
      case "selectWord":
        gameState["currentWord"] = event.payload["word"];
        gameState["selectingWord"] = false;
      case "draw":
        (gameState["currentDrawing"] as List<List<Offset>>)
            .add(deserializeLine(event.payload["line"]));
        break;
      case "undo":
        if (gameState["currentDrawing"].isEmpty) return;
        (gameState["currentDrawing"] as List<List<Offset>>).removeLast();
        break;
      case "turnChange":
        startNewRound(gameState);
        gameState["currentPlayer"] =
            (gameState["currentPlayer"] + 1) % players.length;
        break;
      case "guess":
        String word = event.payload["word"].trim();
        if (gameState["currentWord"].toLowerCase() == word.toLowerCase()) {
          if ((gameState["currentScorers"] as List<Player>).isEmpty) {
            gameState["scores"][event.author] += 3;
            gameState["scores"][players[gameState["currentPlayer"]]] += 2;
            (gameState["currentGuesses"] as List<Pair<Player, String>>)
                .add(Pair(event.author, "successfully guessed the word first"));
          } else {
            gameState["scores"][event.author] += 1;
            (gameState["currentGuesses"] as List<Pair<Player, String>>)
                .add(Pair(event.author, "successfully guessed the word"));
          }
          (gameState["currentScorers"] as List<Player>).add(event.author);
        } else {
          (gameState["currentGuesses"] as List<Pair<Player, String>>)
              .add(Pair(event.author, word));
        }
        if ((gameState["currentScorers"] as List<Player>).length ==
            players.length - 1) {
          startNewRound(gameState);
          gameState["currentPlayer"] =
              (gameState["currentPlayer"] + 1) % players.length;
        }
        break;
      default:
    }
  }

  void startNewRound(Map<String, dynamic> gameState) {
    gameState["currentDrawing"] = <List<Offset>>[];
    gameState["currentGuesses"] = <Pair<Player, String>>[];
    gameState["currentScorers"] = <Player>[];
    gameState["currentWord"] = "";
    gameState["roundCount"]++;
    gameState["selectingWord"] = true;
    gameState["wordOptions"] = getWordOptions();
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {
    if (gameState["currentPlayer"] == oldPlayers.indexOf(player)) {
      startNewRound(gameState);
    }
    if (gameState["currentPlayer"] >= players.length) {
      gameState["currentPlayer"] = 0;
    }
    if (oldPlayers.indexOf(player) < gameState["currentPlayer"]) {
      gameState["currentPlayer"]--;
    }
  }

  @override
  Map<String, dynamic>? checkGameEnd(
      {required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    if (gameState["roundCount"] < getRoundCount(players.length)) return null;
    final scores = gameState["scores"] as Map<Player, int>;
    final winners = scores.entries
        .where((pair) => pair.value == scores.values.max)
        .map((pair) => pair.key);
    return {"winnerName": winners.map((p) => p.name).join(", "), "draw": false};
  }
}
