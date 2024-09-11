import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:pair/pair.dart';

class NotPlayerTurn extends CheckResultFailure {
  const NotPlayerTurn() : super("Not player's turn");
}

class OutOfBounds extends CheckResultFailure {
  const OutOfBounds() : super("Position out of bounds");
}

class PositionAlreadyTaken extends CheckResultFailure {
  const PositionAlreadyTaken() : super("Position already taken");
}

class TicTacToe extends Game {
  // Game ID name
  @override
  String get name => "Tic Tac Toe";

  // Number of max allowed players
  @override
  int get playerLimit => 2;

  // Return game state before moves are performed.
  @override
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players, required Player host}) {
    return {"currentPlayer": 0, "board": List.filled(9, -1)};
  }

  // Check if player can perform an event and return data.
  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Player host,
      required Map<String, dynamic> gameState,
      required List<Player> players}) {
    if (players[gameState["currentPlayer"]] != player) {
      return const NotPlayerTurn();
    }
    if (event["position"] < 0 || event["position"] >= 9) {
      return const OutOfBounds();
    }
    if (gameState["board"][event["position"]] != -1) {
      return const PositionAlreadyTaken();
    }
    return const CheckResultSuccess();
  }

  // Process new event and return if it was successful.
  @override
  void processEvent(
      {required Event event,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    gameState["board"][event.payload["position"]] = gameState["currentPlayer"];
    gameState["currentPlayer"] += 1;
    gameState["currentPlayer"] %= players.length;
  }

  // Handle when new player joins.
  @override
  void onPlayerJoin(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    if (players.length >= 2) gameState["hasRequiredPlayers"] = true;
  }

  // Handle when player leaves room.
  @override
  void onPlayerLeave(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    if (players.length < 2) gameState["hasRequiredPlayers"] = false;
    if (gameState["currentPlayer"] >= players.length) {
      gameState["currentPlayer"] = 0;
    }
  }

  Pair<int, int> getMatrixPosition(int position) {
    if (position < 0) return const Pair(-1, -1);
    return Pair(position ~/ 3, position % 3);
  }

  bool positionOutOfBounds(int posRow, int posCol) {
    return posRow < 0 || posRow >= 3 || posCol < 0 || posCol >= 3;
  }

  int countDirection(int posRow, int posCol, int dirRow, int dirCol,
      List<int> board, int icon) {
    if (positionOutOfBounds(posRow, posCol)) return 0;
    if (icon != board[posRow * 3 + posCol]) return 0;
    return 1 +
        countDirection(
            posRow + dirRow, posCol + dirCol, dirRow, dirCol, board, icon);
  }

  int getWinner(Map<String, dynamic> gameState) {
    final board = List<int>.from(gameState["board"]);
    for (var position = 0; position < 9; position++) {
      final matrixPosition = getMatrixPosition(position);
      final directions = [
        const Pair(1, 0),
        const Pair(1, 1),
        const Pair(0, 1),
        const Pair(-1, 1)
      ];
      final icon = board[position];
      if (icon == -1) continue;
      for (var direction in directions) {
        var count = countDirection(matrixPosition.key, matrixPosition.value,
                direction.key, direction.value, board, icon) +
            countDirection(matrixPosition.key, matrixPosition.value,
                -direction.key, -direction.value, board, icon) -
            1;
        if (count >= 3) return board[position];
      }
    }
    return -1;
  }

  bool getDraw(Map<String, dynamic> gameState) {
    return !gameState["board"].any((e) => e == -1);
  }

  // Determine when the game has ended and return game end data.
  @override
  Map<String, dynamic>? checkGameEnd(
      {required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    final winner = getWinner(gameState);
    if (winner != -1) {
      return {"winnerName": players[winner].name, "draw": false};
    }
    if (getDraw(gameState)) return {"draw": true};
    return null;
  }
}
