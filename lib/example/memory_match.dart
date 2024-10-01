import 'dart:convert';
import 'dart:math';

import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';

class NotPlayerTurn extends CheckResultFailure {
  const NotPlayerTurn() : super("Not your turn");
}

// class NotSelectable extends CheckResultFailure {
//   const NotSelectable() : super("Can't choose that option");
// }

class CardAlreadyFlipped extends CheckResultFailure {
  const CardAlreadyFlipped() : super("Card is already flipped");
}

class MemoryMatch extends Game {
  // Game ID name
  @override
  String get name => "Memory Match";

  // Count of required players to play
  @override
  int get requiredPlayers => 2;

  // Number of max allowed players
  @override
  int get playerLimit => 4;

  @override
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    // TODO: implement getInitialGameState
    List<MemoryCard> cards = [];
    int initialAscii = ascii.encode("A")[0];
    for (var i = 0; i < 15; i++) {
      cards.addAll([
        MemoryCard(symbol: String.fromCharCode(initialAscii + i)),
        MemoryCard(symbol: String.fromCharCode(initialAscii + i))
      ]);
    }
    cards.shuffle(random);
    return {"currentPlayer": 0, "layout": cards, "currentlyFlipped": []};
  }
  // gameState = {
  // "currentPlayer": index of who's ever turn it is,
  // "layout": [all cards in order they are placed],
  // "currentlyFlipped: [indexes of cards flipped during current player's turn]
  // }

  // event = {
  //   "position": index of card to flip
  // }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    // TODO: implement checkPerformEvent
    if (players[gameState["currentPlayer"]] != player) {
      return const NotPlayerTurn();
    }
    // if (event["position"] < 0 || event["position"] >= 30) {
    //   return const NotSelectable();
    // }
    if (event["position"] >= 0) {
      if (gameState["layout"][event["position"]].isFlipped()) {
        return const CardAlreadyFlipped();
      }
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
    // TODO: implement
    int position = event.payload["position"];

    gameState["currentlyFlipped"].add(position);
    if (position >= 0 && position < gameState["layout"].length) {
      gameState["layout"][position].flipCard();
    }
    if (gameState["currentlyFlipped"].length > 2) {
      MemoryCard card1 = gameState["layout"][gameState["currentlyFlipped"][0]];
      MemoryCard card2 = gameState["layout"][gameState["currentlyFlipped"][1]];
      if (card1.symbol == card2.symbol) {
        card1.playerMatched = event.author;
        card2.playerMatched = event.author;
      } else {
        card1.flipCard();
        card2.flipCard();
        if (gameState["currentPlayer"] < players.length - 1) {
          gameState["currentPlayer"] += 1;
        } else {
          gameState["currentPlayer"] = 0;
        }
      }
      gameState["currentlyFlipped"] = [];
    }
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    // TODO: implement onPlayerLeave
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
    // TODO: implement checkGameEnd
    Map<Player, int> scores = {};
    for (MemoryCard card in gameState["layout"]) {
      Player? matchedPlayer = card.playerMatched;
      if (matchedPlayer == null) {
        return null;
      } else if (scores[matchedPlayer] == null) {
        scores[matchedPlayer] = 1;
      } else {
        scores[matchedPlayer] = scores[matchedPlayer]! + 1;
      }
    }
    List<Player> winnerList = getHighestScorePlayers(scores);
    return {"winnerName": winnerList[0].name, "draw": winnerList.length > 1};
  }

  List<Player> getHighestScorePlayers(Map<Player, int> scores) {
    List<Player> highestScorePlayers = [];
    int highestScore = 0;
    scores.forEach((playerName, score) {
      if (score > highestScore) {
        highestScore = score;
        highestScorePlayers = [playerName];
      } else if (score == highestScore) {
        highestScorePlayers.add(playerName);
      }
    });
    return highestScorePlayers;
  }
}

class MemoryCard {
  final String symbol;

  bool flipped;

  Player? playerMatched;

  MemoryCard({required this.symbol, this.flipped = false, this.playerMatched});

  bool isFlipped() => flipped;

  void flipCard() {
    flipped = !flipped;
  }

  Map<String, dynamic> toJson() =>
      {"symbol": symbol, "flipped": flipped, "playerMatched": playerMatched};

  static MemoryCard fromJson(Map<String, dynamic> json) => MemoryCard(
      symbol: json["symbol"],
      flipped: json["flipped"],
      playerMatched: json["playerMatched"]);
}
