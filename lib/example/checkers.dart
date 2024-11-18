import 'dart:math';
import 'dart:ui';

import 'package:either_dart/either.dart';
import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:pair/pair.dart';

class CheckersRoute {
  final Pair<int, int> start;
  final Pair<int, int> end;
  final List<Pair<int, int>> intermediates;

  const CheckersRoute(
      {required this.start, required this.end, required this.intermediates});

  static Map<String, int> positionToMap(Pair<int, int> position) {
    return {"key": position.key, "value": position.value};
  }

  Map<String, dynamic> toJson() => {
        "start": positionToMap(start),
        "end": positionToMap(end),
        "intermediates": intermediates.map((e) => positionToMap(e)).toList(),
      };

  List<Pair<int, int>> get positions => [start] + intermediates + [end];

  bool get isPassive =>
      intermediates.isEmpty && (start.value - end.value).abs() == 1;

  bool positionInRoute(Pair<int, int> position) =>
      intermediates.contains(position) || end == position;

  static Pair<int, int> positionFromMap(Map<String, dynamic> map) {
    return Pair<int, int>(map["key"]!, map["value"]!);
  }

  static CheckersRoute fromJson(Map<String, dynamic> json) => CheckersRoute(
      start: positionFromMap(json["start"]),
      end: positionFromMap(json["end"]),
      intermediates: json["intermediates"]
          .map((e) => positionFromMap(e))
          .toList()
          .cast<Pair<int, int>>());
}

enum CheckersPiece {
  black(key: "black", possibleRoutes: possibleRoutesBlack),
  blackKing(key: "blackKing", possibleRoutes: possibleRoutesKing),
  red(key: "red", possibleRoutes: possibleRoutesRed),
  redKing(key: "redKing", possibleRoutes: possibleRoutesKing);

  static const blacks = [black, blackKing];
  static const reds = [red, redKing];

  List<CheckersPiece> get enemies {
    return blacks.contains(this) ? reds : blacks;
  }

  bool get isKing => this == blackKing || this == redKing;

  static const List<Pair<int, int>> blackDirections = [
    Pair(-1, -1),
    Pair(-1, 1)
  ];
  static const List<Pair<int, int>> redDirections = [Pair(1, -1), Pair(1, 1)];
  static const List<Pair<int, int>> kingDirections = [
    Pair(-1, -1),
    Pair(-1, 1),
    Pair(1, -1),
    Pair(1, 1)
  ];

  static bool isOutOfBounds(int row, int col, List<List> board) {
    return row < 0 ||
        row >= board.length ||
        col < 0 ||
        col >= board.first.length;
  }

  static List<CheckersRoute> possibleRoutesByDirection(Pair<int, int> position,
      List<List<CheckersPiece?>> board, List<Pair<int, int>> directions) {
    List<CheckersRoute> checkNearbyPositions(Pair<int, int> position,
        List<List<CheckersPiece?>> board, List<Pair<int, int>> directions) {
      final routes = <CheckersRoute>[];
      for (var direction in directions) {
        int row = position.key + direction.key;
        int col = position.value + direction.value;
        if (isOutOfBounds(row, col, board)) continue;
        final piece = board[row][col];
        if (piece != null) continue;
        routes.add(CheckersRoute(
            start: position, end: Pair(row, col), intermediates: []));
      }
      return routes;
    }

    void helper(
        List<List<CheckersPiece?>> board,
        List<Pair<int, int>> directions,
        Pair<int, int> currentPosition,
        List<CheckersPiece> enemies,
        CheckersRoute? currentRoute,
        List<CheckersRoute> routes) {
      for (var direction in directions) {
        if (isOutOfBounds(currentPosition.key + direction.key,
                currentPosition.value + direction.value, board) ||
            isOutOfBounds(currentPosition.key + 2 * direction.key,
                currentPosition.value + 2 * direction.value, board)) continue;
        final enemy = board[currentPosition.key + direction.key]
            [currentPosition.value + direction.value];
        final target = board[currentPosition.key + 2 * direction.key]
            [currentPosition.value + 2 * direction.value];
        if (enemy == null || !enemies.contains(enemy)) continue;
        if (target != null) continue;
        final targetPosition = Pair(currentPosition.key + 2 * direction.key,
            currentPosition.value + 2 * direction.value);
        if (currentRoute?.positionInRoute(targetPosition) ?? false) continue;
        final route = CheckersRoute(
            start: currentRoute?.start ?? currentPosition,
            end: targetPosition,
            intermediates: currentRoute != null
                ? currentRoute.intermediates + [currentRoute.end]
                : []);
        routes.add(route);
        helper(board, directions, targetPosition, enemies, route, routes);
      }
    }

    final piece = board[position.key][position.value];
    if (piece == null) return [];
    final routes = checkNearbyPositions(position, board, directions);
    helper(board, directions, position, piece.enemies, null, routes);
    return routes;
  }

  static List<CheckersRoute> possibleRoutesBlack(
      Pair<int, int> position, List<List<CheckersPiece?>> board) {
    return possibleRoutesByDirection(position, board, blackDirections);
  }

  static List<CheckersRoute> possibleRoutesRed(
      Pair<int, int> position, List<List<CheckersPiece?>> board) {
    return possibleRoutesByDirection(position, board, redDirections);
  }

  static List<CheckersRoute> possibleRoutesKing(
      Pair<int, int> position, List<List<CheckersPiece?>> board) {
    return possibleRoutesByDirection(position, board, kingDirections);
  }

  final String key;
  final List<CheckersRoute> Function(Pair<int, int>, List<List<CheckersPiece?>>)
      possibleRoutes;

  const CheckersPiece({required this.key, required this.possibleRoutes});

  static CheckersPiece fromKey(String key) =>
      CheckersPiece.values.where((e) => e.key == key).first;
}

enum CheckersRequestType {
  isCurrentPlayer,
  playerOwnsPiece,
  getPossibleRoutes,
  getPieceColor,
  getBoard,
}

class CheckersGameState extends GameState {
  int currentPlayer;
  List<String?> board;

  CheckersGameState({required this.currentPlayer, required this.board});
}

class Checkers extends Game {
  static List<List<CheckersPiece?>> toBoard(List<String?> jsonBoard) {
    final board = <List<CheckersPiece?>>[];
    for (var i = 0; i < jsonBoard.length; i += 8) {
      board.add(jsonBoard
          .sublist(i, i + 8)
          .map((jsonPiece) =>
              jsonPiece == null ? null : CheckersPiece.fromKey(jsonPiece))
          .toList());
    }
    return board;
  }

  static List<String?> fromBoard(List<List<CheckersPiece?>> board) {
    return board.expand((rows) => rows.map((piece) => piece?.key)).toList();
  }

  static List<CheckersPiece> getPiecesFromIndex(int i) =>
      i == 0 ? CheckersPiece.blacks : CheckersPiece.reds;

  static int getIndexFromPiece(CheckersPiece piece) =>
      CheckersPiece.blacks.contains(piece) ? 0 : 1;

  @override
  String get name => "Checkers";

  @override
  int get requiredPlayers => 2;

  @override
  int get playerLimit => 2;

  @override
  GameState getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    final board = List.generate(
        8,
        (i) => List.generate(8, (j) {
              if ((i + j) % 2 == 0) return null;
              if (i < 3) return CheckersPiece.red;
              if (i >= 5) return CheckersPiece.black;
              return null;
            }));
    return CheckersGameState(currentPlayer: 0, board: fromBoard(board));
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required covariant CheckersGameState gameState,
      required List<Player> players,
      required Player host}) {
    if (players[gameState.currentPlayer] != player) {
      return const NotPlayerTurn();
    }
    return const CheckResultSuccess();
  }

  @override
  void processEvent(
      {required GameEvent event,
      required covariant CheckersGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    final board = toBoard(gameState.board);
    final route = CheckersRoute.fromJson(event.payload["route"]);
    if (!route.isPassive) {
      for (var i = 0; i < route.positions.length - 1; i++) {
        final start = route.positions[i];
        final end = route.positions[i + 1];
        board[(start.key + end.key) ~/ 2][(start.value + end.value) ~/ 2] =
            null;
      }
    }
    board[route.end.key][route.end.value] =
        board[route.start.key][route.start.value];
    board[route.start.key][route.start.value] = null;
    final kingRow = [0, 7];
    final kingTransformation = [CheckersPiece.blackKing, CheckersPiece.redKing];
    if (route.end.key == kingRow[gameState.currentPlayer]) {
      board[route.end.key][route.end.value] =
          kingTransformation[gameState.currentPlayer];
    }
    gameState.board = fromBoard(board);
    gameState.currentPlayer += 1;
    gameState.currentPlayer %= players.length;
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required covariant CheckersGameState gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {
    if (gameState.currentPlayer >= players.length) {
      gameState.currentPlayer = 0;
    }
  }

  @override
  Map<String, dynamic>? checkGameEnd(
      {required covariant CheckersGameState gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    final board = toBoard(gameState.board);
    final counts = {0: 0, 1: 0};
    for (var i = 0; i < board.length; i++) {
      for (var j = 0; j < board.first.length; j++) {
        final piece = board[i][j];
        if (piece == null) continue;
        counts[getIndexFromPiece(piece)] = counts[getIndexFromPiece(piece)]! +
            piece.possibleRoutes(Pair(i, j), board).length;
      }
    }
    if (counts[0] == 0 && counts[1] == 0) return {"draw": true};
    if (counts[0] == 0) return {"draw": false, "winnerName": players[1].name};
    if (counts[1] == 0) return {"draw": false, "winnerName": players[0].name};
    return null;
  }

  @override
  Either<CheckResultFailure, dynamic> getGameResponse(
      {required Map<String, dynamic> request,
      required Player player,
      required covariant CheckersGameState gameState,
      required List<Player> players,
      required Player host}) {
    switch (request["type"] as CheckersRequestType) {
      case CheckersRequestType.isCurrentPlayer:
        if (players[gameState.currentPlayer] != player) {
          return const Left(CheckResultFailure("Not your turn."));
        }
        return const Right(null);
      case CheckersRequestType.playerOwnsPiece:
        return Right(
            players.indexOf(player) == getIndexFromPiece(request["piece"]));
      case CheckersRequestType.getPossibleRoutes:
        final board = toBoard(gameState.board);
        final position = request["position"];
        final piece = board[position.key][position.value];
        if (piece == null) {
          return const Left(CheckResultFailure());
        }
        if (players.indexOf(player) != getIndexFromPiece(piece)) {
          return const Left(CheckResultFailure("Not your piece."));
        }
        final routes =
            piece.possibleRoutes(Pair(position.key, position.value), board);
        if (routes.isEmpty) {
          return const Left(CheckResultFailure("Piece can't move."));
        }
        return Right(routes);

      case CheckersRequestType.getPieceColor:
        return Right(getIndexFromPiece(request["piece"]) == 0
            ? const Color.fromRGBO(103, 58, 183, 1)
            : const Color.fromRGBO(239, 80, 80, 1));
      case CheckersRequestType.getBoard:
        return Right(toBoard(gameState.board));
    }
  }
}
