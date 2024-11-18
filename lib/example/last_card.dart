import 'dart:math';
import 'dart:ui';

import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:fire_game_infra/fire_game_infra.dart';

enum LastCardType {
  number(cardValues: [
    LastCardValue.zero,
    LastCardValue.one,
    LastCardValue.two,
    LastCardValue.three,
    LastCardValue.four,
    LastCardValue.five,
    LastCardValue.six,
    LastCardValue.seven,
    LastCardValue.eight,
    LastCardValue.nine
  ]),
  skip(cardValues: [LastCardValue.skip]),
  reverse(cardValues: [LastCardValue.reverse]),
  plusTwo(cardValues: [LastCardValue.plusTwo]),
  wild(cardValues: [LastCardValue.wild]),
  wildPlusFour(cardValues: [LastCardValue.wildPlusFour]);

  final List<LastCardValue> cardValues;

  const LastCardType({required this.cardValues});

  static LastCardType fromValue(LastCardValue value) => LastCardType.values
      .where((type) => type.cardValues.contains(value))
      .first;

  bool get isWild => this == wild || this == wildPlusFour;
}

enum LastCardValue {
  zero(key: "0", text: "0", totalCount: 1),
  one(key: "1", text: "1", totalCount: 2),
  two(key: "2", text: "2", totalCount: 2),
  three(key: "3", text: "3", totalCount: 2),
  four(key: "4", text: "4", totalCount: 2),
  five(key: "5", text: "5", totalCount: 2),
  six(key: "6", text: "6", totalCount: 2),
  seven(key: "7", text: "7", totalCount: 2),
  eight(key: "8", text: "8", totalCount: 2),
  nine(key: "9", text: "9", totalCount: 2),
  skip(key: "skip", text: "🚫", totalCount: 2),
  reverse(key: "reverse", text: "🔃", totalCount: 2),
  plusTwo(key: "plusTwo", text: "+2", totalCount: 2),
  wild(key: "wild", text: "🎨", totalCount: 4),
  wildPlusFour(key: "wildPlusFour", text: "🎨+4", totalCount: 4);

  final String key;
  final String text;
  final int totalCount;

  const LastCardValue(
      {required this.key, required this.text, required this.totalCount});

  static LastCardValue fromKey(String key) =>
      values.where((e) => e.key == key).first;
}

enum LastCardColor {
  red(key: "red", color: Color.fromRGBO(252, 29, 100, 1.0)),
  green(key: "green", color: Color.fromRGBO(122, 150, 66, 1.0)),
  blue(key: "blue", color: Color.fromRGBO(30, 144, 255, 1.0)),
  yellow(key: "yellow", color: Color.fromRGBO(255, 194, 0, 1.0));

  final String key;
  final Color color;

  const LastCardColor({required this.key, required this.color});

  static LastCardColor fromKey(String key) =>
      values.where((e) => e.key == key).first;
}

class LastCardCard {
  final LastCardValue value;
  final LastCardColor? color;

  const LastCardCard({required this.value, required this.color});

  static List<LastCardCard> get cardSet {
    final coloredTypes = [
      LastCardType.number,
      LastCardType.skip,
      LastCardType.reverse,
      LastCardType.plusTwo
    ];
    final wildTypes = [LastCardType.wild, LastCardType.wildPlusFour];
    return coloredTypes
            .expand((type) => type.cardValues.expand((value) =>
                LastCardColor.values.expand((color) => List.filled(
                    value.totalCount,
                    LastCardCard(value: value, color: color)))))
            .toList() +
        wildTypes
            .expand((type) => type.cardValues.expand((value) => List.filled(
                value.totalCount, LastCardCard(value: value, color: null))))
            .toList();
  }

  static List<LastCardCard> getRandomCards(int count, Random random) {
    final cards = cardSet;
    return List.generate(count, (_) => cards[random.nextInt(cardSet.length)]);
  }

  static List<LastCardCard> sortCards(List<LastCardCard> cards) {
    cards.sort((a, b) {
      if (a.color == null && b.color != null) return 1;
      if (a.color != null && b.color == null) return -1;
      if (a.color != null && b.color != null) {
        const colors = LastCardColor.values;
        int colorCompare = colors.indexOf(a.color!) - colors.indexOf(b.color!);
        if (colorCompare != 0) return colorCompare;
      }
      const values = LastCardValue.values;
      return values.indexOf(a.value) - values.indexOf(b.value);
    });
    return cards;
  }

  Map<String, dynamic> toJson() => {
        "value": value.key,
        "color": color?.key,
      };

  static LastCardCard fromJson(Map<String, dynamic> json) => LastCardCard(
      value: LastCardValue.fromKey(json["value"]),
      color:
          json["color"] != null ? LastCardColor.fromKey(json["color"]) : null);

  @override
  bool operator ==(Object other) {
    return other is LastCardCard &&
        (color == other.color || color == null || other.color == null) &&
        value == other.value;
  }
}

class LastCardGameState extends GameState {
  int currentPlayer;
  Map<Player, List<LastCardCard>> playerCards;
  List<LastCardCard> playedCards;
  int direction;

  LastCardGameState(
      {required this.currentPlayer,
      required this.playerCards,
      required this.playedCards,
      required this.direction});
}

class LastCard extends Game {
  @override
  String get name => "Last Card";

  @override
  int get requiredPlayers => 2;

  @override
  int get playerLimit => 4;

  @override
  GameState getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    final cards = LastCardCard.getRandomCards(7 * players.length, random);
    final playerCardsList = List.generate(players.length,
        (i) => LastCardCard.sortCards(cards.sublist(i * 7, (i + 1) * 7)));
    final playerCards = <Player, List<LastCardCard>>{};
    for (var i = 0; i < players.length; i++) {
      playerCards[players[i]] = playerCardsList[i];
    }
    LastCardCard startingCard;
    do {
      startingCard = LastCardCard.getRandomCards(1, random).first;
    } while (startingCard.color == null);
    return LastCardGameState(
        currentPlayer: 0,
        playerCards: playerCards,
        playedCards: [startingCard],
        direction: 1);
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required covariant LastCardGameState gameState,
      required List<Player> players,
      required Player host}) {
    if (players.indexOf(player) != gameState.currentPlayer) {
      return const NotPlayerTurn();
    }
    final topCard = gameState.playedCards.last;
    if (event["isPlace"] ?? false) {
      final card = LastCardCard.fromJson(event["card"]);
      if (card.color != null &&
          card.color != topCard.color &&
          card.value != topCard.value) {
        return const CheckResultFailure("Card cannot be placed");
      }
    } else if (event["isDraw"] ?? false) {
      if (gameState.playerCards[player]!.any((card) =>
          card.color == null ||
          card.color == topCard.color ||
          card.value == topCard.value)) {
        return const CheckResultFailure("There is a usable card in hand");
      }
    }
    return const CheckResultSuccess();
  }

  void moveOneTurn(LastCardGameState gameState, int playerCount) {
    gameState.currentPlayer =
        (gameState.currentPlayer + playerCount + gameState.direction) %
            playerCount;
  }

  void reverseDirection(LastCardGameState gameState) {
    gameState.direction *= -1;
  }

  List<LastCardCard> addCardsToPlayer(
      LastCardGameState gameState, Player player, int count, Random random) {
    final cards = LastCardCard.getRandomCards(count, random);
    gameState.playerCards[player]!.addAll(cards);
    LastCardCard.sortCards(gameState.playerCards[player]!);
    return cards;
  }

  @override
  void processEvent(
      {required GameEvent event,
      required covariant LastCardGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    if (event.payload["isPlace"] ?? false) {
      var card = LastCardCard.fromJson(event.payload["card"]);
      final cardType = LastCardType.fromValue(card.value);
      if (cardType.isWild) {
        card = LastCardCard(
            value: card.value,
            color: LastCardColor.fromKey(event.payload["color"]));
      }
      switch (cardType) {
        case LastCardType.number:
          break;
        case LastCardType.skip:
          moveOneTurn(gameState, players.length);
          break;
        case LastCardType.reverse:
          if (players.length <= 2) moveOneTurn(gameState, players.length);
          reverseDirection(gameState);
          break;
        case LastCardType.plusTwo:
          moveOneTurn(gameState, players.length);
          addCardsToPlayer(
              gameState, players[gameState.currentPlayer], 2, random);
          break;
        case LastCardType.wild:
          break;
        case LastCardType.wildPlusFour:
          moveOneTurn(gameState, players.length);
          addCardsToPlayer(
              gameState, players[gameState.currentPlayer], 4, random);
          break;
      }
      gameState.playedCards.add(card);
      gameState.playerCards[event.author]!.remove(card);
      moveOneTurn(gameState, players.length);
    } else if (event.payload["isDraw"] ?? false) {
      final card = addCardsToPlayer(gameState, event.author, 1, random).first;
      final topCard = gameState.playedCards.last;
      if (card.color != null &&
          card.color != topCard.color &&
          card.value != topCard.value) {
        moveOneTurn(gameState, players.length);
      }
    }
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required covariant LastCardGameState gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {
    int leaveIndex = oldPlayers.indexOf(player);
    if (leaveIndex == gameState.currentPlayer) {
      gameState.currentPlayer = (gameState.currentPlayer +
              (gameState.direction > 0 ? 0 : -1) +
              players.length) %
          players.length;
    } else if (leaveIndex < gameState.currentPlayer) {
      gameState.currentPlayer -= 1;
    }
  }

  @override
  Map<String, dynamic>? checkGameEnd(
      {required covariant LastCardGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    for (var player in players) {
      if (gameState.playerCards[player]!.isEmpty) {
        return {"draw": false, "winnerName": player.name};
      }
    }
    return null;
  }
}
