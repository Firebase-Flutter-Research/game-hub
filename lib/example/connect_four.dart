import 'dart:math';

import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:pair/pair.dart';

class ConnectFourGameState extends GameState {
  int currentPlayer;
  List<int> board;
  int? lastPosition;

  ConnectFourGameState({required this.currentPlayer, required this.board});
}

class ConnectFour extends Game {
  @override
  String get name => "Four in a Row";

  @override
  int get requiredPlayers => 2;

  @override
  int get playerLimit => 2;

  static const int width = 7;
  static const int height = 6;

  @override
  GameState getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    return ConnectFourGameState(
        currentPlayer: 0, board: List.filled(width * height, -1));
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required covariant ConnectFourGameState gameState,
      required List<Player> players,
      required Player host}) {
    if (players[gameState.currentPlayer] != player) {
      return const CheckResultFailure("Not your turn");
    }
    int position = event["position"];
    if (position < 0 || position >= width) {
      return const CheckResultFailure("Position out of bounds");
    }
    for (int newPosition = position + width * (height - 1);
        newPosition >= 0;
        newPosition -= width) {
      if (gameState.board[newPosition] != -1) continue;
      return const CheckResultSuccess();
    }
    return const CheckResultFailure("Column overflows");
  }

  @override
  void processEvent(
      {required GameEvent event,
      required covariant ConnectFourGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    int position = event.payload["position"];
    for (int newPosition = position + width * (height - 1);
        newPosition >= 0;
        newPosition -= width) {
      if (gameState.board[newPosition] != -1) continue;
      gameState.board[newPosition] = gameState.currentPlayer;
      gameState.lastPosition = newPosition;
      gameState.currentPlayer += 1;
      gameState.currentPlayer %= players.length;
      return;
    }
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required covariant ConnectFourGameState gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {
    if (gameState.currentPlayer >= players.length) {
      gameState.currentPlayer = 0;
    }
  }

  Pair<int, int> getMatrixPosition(int position) {
    if (position < 0) return const Pair(-1, -1);
    return Pair(position ~/ width, position % width);
  }

  bool positionOutOfBounds(int posRow, int posCol) {
    return posRow < 0 || posRow >= height || posCol < 0 || posCol >= width;
  }

  int countDirection(int posRow, int posCol, int dirRow, int dirCol,
      List<int> board, int icon) {
    if (positionOutOfBounds(posRow, posCol)) return 0;
    if (icon != board[posRow * width + posCol]) return 0;
    return 1 +
        countDirection(
            posRow + dirRow, posCol + dirCol, dirRow, dirCol, board, icon);
  }

// TODO: does this need 'covariant' keyword?
  int getWinner(ConnectFourGameState gameState) {
    final board = List<int>.from(gameState.board);
    int? position = gameState.lastPosition;
    if (position == null) return -1;
    final matrixPosition = getMatrixPosition(position);
    final directions = [
      const Pair(1, 0),
      const Pair(1, 1),
      const Pair(0, 1),
      const Pair(-1, 1)
    ];
    final icon = board[position];
    if (icon == -1) return -1;
    for (var direction in directions) {
      var count = countDirection(matrixPosition.key, matrixPosition.value,
              direction.key, direction.value, board, icon) +
          countDirection(matrixPosition.key, matrixPosition.value,
              -direction.key, -direction.value, board, icon) -
          1;
      if (count >= 4) return board[position];
    }
    return -1;
  }

  bool getDraw(ConnectFourGameState gameState) {
    return !gameState.board.any((e) => e == -1);
  }

  @override
  Map<String, dynamic>? checkGameEnd(
      {required covariant ConnectFourGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    final winner = getWinner(gameState);
    if (winner != -1) {
      return {"winnerName": players[winner].name, "draw": false};
    }
    if (getDraw(gameState)) return {"draw": true};
    return null;
  }
}
