import 'package:flutter_fire_engine/model/player.dart';

class CheckResult {
  final String? message;

  const CheckResult([this.message]);
}

class CheckResultSuccess extends CheckResult {
  const CheckResultSuccess([super.message]);
}

class CheckResultFailure extends CheckResult {
  const CheckResultFailure([super.message]);
}

abstract class Game {
  // Game ID name
  String get name;

  // Return game state before moves are performed.
  Map<String, dynamic> getInitialGameState({required List<Player> players});

  // Check if player can perform an event and return the result.
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players});

  // Process new event and return if it was successful.
  void processEvent(
      {required Map<String, dynamic> event,
      required Map<String, dynamic> gameState,
      required List<Player> players});

  // Handle when new player joins.
  void onPlayerJoin(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players});

  // Handle when player leaves room.
  void onPlayerLeave(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players});

  // Determine when the game has ended and return game end data.
  Map<String, dynamic>? checkGameEnd(
      {required Map<String, dynamic> gameState, required List<Player> players});
}
