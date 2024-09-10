import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:pair/pair.dart';
import 'package:collection/collection.dart';

enum PieceType {
  pawn(id: "p", possibleTargets: possibleTargetsPawn),
  rook(id: "r", possibleTargets: possibleTargetsRook),
  bishop(id: "b", possibleTargets: possibleTargetsBishop),
  knight(id: "n", possibleTargets: possibleTargetsKnight),
  queen(id: "q", possibleTargets: possibleTargetsQueen),
  king(id: "k", possibleTargets: possibleTargetsKing);

  static List<String> possibleTargetsPawn(
      List<List<Piece?>> board, String position) {
    final matrixPosition = Chess.getMatrixPosition(position);
    if (matrixPosition == null) return [];
    final piece = board[matrixPosition.key][matrixPosition.value];
    if (piece == null) return [];
    final pawnStart = piece.color == PieceColor.white ? 6 : 1;
    final pawnDirection = piece.color == PieceColor.white ? -1 : 1;
    final targets = <String>[];
    if (matrixPosition.key == pawnStart &&
        board[matrixPosition.key + 2 * pawnDirection][matrixPosition.value] ==
            null) {
      targets.add(Chess.fromMatrixPosition(
          Pair(matrixPosition.key + 2 * pawnDirection, matrixPosition.value)));
    }
    if (matrixPosition.key + pawnDirection >= 0 &&
        matrixPosition.key + pawnDirection < 8 &&
        board[matrixPosition.key + pawnDirection][matrixPosition.value] ==
            null) {
      targets.add(Chess.fromMatrixPosition(
          Pair(matrixPosition.key + pawnDirection, matrixPosition.value)));
    }
    if (matrixPosition.value > 0 &&
        board[matrixPosition.key + pawnDirection][matrixPosition.value - 1] !=
            null &&
        board[matrixPosition.key + pawnDirection][matrixPosition.value - 1]!
                .color ==
            piece.color.opposite) {
      targets.add(Chess.fromMatrixPosition(
          Pair(matrixPosition.key + pawnDirection, matrixPosition.value - 1)));
    }
    if (matrixPosition.value < 7 &&
        board[matrixPosition.key + pawnDirection][matrixPosition.value + 1] !=
            null &&
        board[matrixPosition.key + pawnDirection][matrixPosition.value + 1]!
                .color ==
            piece.color.opposite) {
      targets.add(Chess.fromMatrixPosition(
          Pair(matrixPosition.key + pawnDirection, matrixPosition.value + 1)));
    }
    return targets;
  }

  static List<String> getTargetsFromDirections(List<List<Piece?>> board,
      String position, List<Pair<int, int>> directions) {
    void helper(
        List<List<Piece?>> board,
        Pair<int, int> position,
        Pair<int, int> direction,
        List<String> positions,
        PieceColor enemyColor) {
      if (position.key < 0 ||
          position.key >= 8 ||
          position.value < 0 ||
          position.value >= 8) return;
      if (board[position.key][position.value] != null &&
          board[position.key][position.value]!.color == enemyColor) {
        positions.add(Chess.fromMatrixPosition(position));
        return;
      }
      positions.add(Chess.fromMatrixPosition(position));
      helper(
          board,
          Pair(position.key + direction.key, position.value + direction.value),
          direction,
          positions,
          enemyColor);
    }

    final matrixPosition = Chess.getMatrixPosition(position);
    if (matrixPosition == null) return [];
    final piece = board[matrixPosition.key][matrixPosition.value];
    if (piece == null) return [];
    final positions = <String>[];
    for (var direction in directions) {
      helper(
          board,
          Pair(matrixPosition.key + direction.key,
              matrixPosition.value + direction.value),
          direction,
          positions,
          piece.color.opposite);
    }
    return positions;
  }

  static const List<Pair<int, int>> rookDirections = [
    Pair(1, 0),
    Pair(-1, 0),
    Pair(0, 1),
    Pair(0, -1)
  ];
  static const List<Pair<int, int>> bishopDirections = [
    Pair(1, 1),
    Pair(-1, 1),
    Pair(1, -1),
    Pair(-1, -1)
  ];

  static List<String> possibleTargetsRook(
      List<List<Piece?>> board, String position) {
    return getTargetsFromDirections(board, position, rookDirections);
  }

  static List<String> possibleTargetsBishop(
      List<List<Piece?>> board, String position) {
    return getTargetsFromDirections(board, position, bishopDirections);
  }

  static List<String> possibleTargetsKnight(
      List<List<Piece?>> board, String position) {
    const relativePositions = [
      Pair(-2, -1),
      Pair(-2, 1),
      Pair(2, -1),
      Pair(2, 1),
      Pair(-1, -2),
      Pair(1, -2),
      Pair(-1, 2),
      Pair(1, 2)
    ];
    final targets = <String>[];
    final matrixPosition = Chess.getMatrixPosition(position);
    if (matrixPosition == null) return [];
    final piece = board[matrixPosition.key][matrixPosition.value];
    if (piece == null) return [];
    for (var relativePosition in relativePositions) {
      final row = matrixPosition.key + relativePosition.key;
      final col = matrixPosition.value + relativePosition.value;
      if (row >= 0 && row < 8 && col >= 0 && col < 8) {
        final currentPiece = board[row][col];
        if (currentPiece == null ||
            currentPiece.color == piece.color.opposite) {
          targets.add(Chess.fromMatrixPosition(Pair(row, col)));
        }
      }
    }
    return targets;
  }

  static List<String> possibleTargetsQueen(
      List<List<Piece?>> board, String position) {
    return getTargetsFromDirections(
        board, position, rookDirections + bishopDirections);
  }

  static List<String> possibleTargetsKing(
      List<List<Piece?>> board, String position) {
    final targets = <String>[];
    final matrixPosition = Chess.getMatrixPosition(position);
    if (matrixPosition == null) return [];
    final piece = board[matrixPosition.key][matrixPosition.value];
    if (piece == null) return [];
    for (var direction in rookDirections + bishopDirections) {
      final row = matrixPosition.key + direction.key;
      final col = matrixPosition.value + direction.value;
      if (row >= 0 && row < 8 && col >= 0 && col < 8) {
        final targetPiece = board[row][col];
        if (targetPiece == null || targetPiece.color == piece.color.opposite) {
          targets.add(Chess.fromMatrixPosition(Pair(row, col)));
        }
      }
    }
    final boardWithoutKing = board.map((row) => row.toList()).toList();
    boardWithoutKing[matrixPosition.key][matrixPosition.value] = null;
    final enemyTargets = board.expandIndexed((i, rows) => rows.expandIndexed(
        (j, enemyPiece) => enemyPiece == null || enemyPiece.color == piece.color
            ? <Pair<Piece, List<String>>>[]
            : [
                Pair(
                    enemyPiece,
                    enemyPiece.type.possibleTargets(
                        boardWithoutKing, Chess.fromMatrixPosition(Pair(i, j))))
              ]));
    return targets.toSet().difference(enemyTargets.toSet()).toList();
  }

  static PieceType fromId(String id) {
    return PieceType.values.where((e) => e.id == id).first;
  }

  final String id;
  final List<String> Function(List<List<Piece?>> board, String position)
      possibleTargets;

  const PieceType({required this.id, required this.possibleTargets});
}

enum PieceColor {
  white(id: "w"),
  black(id: "k");

  static PieceColor fromId(String id) {
    return PieceColor.values.where((e) => e.id == id).first;
  }

  final String id;

  const PieceColor({required this.id});

  PieceColor get opposite => this == white ? black : white;
}

class Piece {
  final PieceType type;
  final PieceColor color;

  const Piece({required this.type, required this.color});

  Map<String, dynamic> toJson() => {
        "type": type.id,
        "color": color.id,
      };

  static Piece fromJson(Map<String, dynamic> json) => Piece(
        type: PieceType.fromId(json["type"]),
        color: PieceColor.fromId(json["color"]),
      );
}

class Chess extends Game {
  static String fromMatrixPosition(Pair<int, int> position) {
    return String.fromCharCode("A".codeUnits.first + position.value) +
        (8 - position.key).toString();
  }

  static Pair<int, int>? getMatrixPosition(String position) {
    if (position.length != 2) return null;
    final col = position[0].codeUnits.first - "A".codeUnits.first;
    final row = 8 - int.parse(position[1]);
    if (col < 0 || col >= 8 || row < 0 || row >= 8) return null;
    return Pair(row, col);
  }

  static List<List<Piece?>> toMatrix(List<Map<String, dynamic>?> jsonBoard) {
    final matrix = <List<Piece?>>[];
    for (var i = 0; i < jsonBoard.length; i += 8) {
      matrix.add(jsonBoard
          .sublist(i, i + 8)
          .map((jsonPiece) =>
              jsonPiece == null ? null : Piece.fromJson(jsonPiece))
          .toList());
    }
    return matrix;
  }

  static List<Map<String, dynamic>?> toJsonList(
          List<List<Piece?>> matrixBoard) =>
      matrixBoard
          .expand((rows) => rows.map((piece) => piece?.toJson()))
          .toList();

  static const turnColors = [PieceColor.white, PieceColor.black];

  // Game ID name
  @override
  String get name => "Chess";

  // Return game state before moves are performed.
  @override
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players, required Player host}) {
    List<Piece?> getDiverseRows(PieceColor color) => [
          Piece(type: PieceType.rook, color: color),
          Piece(type: PieceType.knight, color: color),
          Piece(type: PieceType.bishop, color: color),
          Piece(type: PieceType.queen, color: color),
          Piece(type: PieceType.king, color: color),
          Piece(type: PieceType.bishop, color: color),
          Piece(type: PieceType.knight, color: color),
          Piece(type: PieceType.rook, color: color),
        ];

    final matrix = [
          getDiverseRows(PieceColor.black),
          List.filled(
              8, const Piece(type: PieceType.pawn, color: PieceColor.black))
        ] +
        List.filled(6, List.filled(8, null)) +
        [
          List.filled(
              8, const Piece(type: PieceType.pawn, color: PieceColor.white)),
          getDiverseRows(PieceColor.white)
        ];

    return {
      "board": toJsonList(matrix),
      "currentPlayer": 0,
    };
  }

  // Check if player can perform an event and return the result.
  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    final position = event["position"];
    final matrixPosition = getMatrixPosition(position);
    final target = event["target"];
    if (matrixPosition == null) {
      return const CheckResultFailure("Invalid position");
    }
    final board = toMatrix(gameState["board"]);
    final piece = board[matrixPosition.key][matrixPosition.value];
    if (piece == null) return const CheckResultFailure("No piece at position");
    if (turnColors[gameState["currentPlayer"]] != piece.color) {
      return const CheckResultFailure("Not player's piece");
    }
    final targets = piece.type.possibleTargets(board, position);
    if (!targets.contains(target)) {
      return const CheckResultFailure("Piece cannot be placed there");
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
    final board = toMatrix(gameState["board"]);
    final position = getMatrixPosition(event.payload["position"]);
    final target = getMatrixPosition(event.payload["target"]);
    final piece = board[position!.key][position.value];
    board[position.key][position.value] = null;
    board[target!.key][target.value] = piece;
    if (piece!.type == PieceType.pawn) {
      final pawnEnd = piece.color == PieceColor.white ? 0 : 7;
      if (target.key == pawnEnd) {
        board[target.key][target.value] =
            Piece(type: PieceType.queen, color: piece.color);
      }
    }
    gameState["board"] = toJsonList(board);
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

  // Determine when the game has ended and return game end data.
  @override
  Map<String, dynamic>? checkGameEnd(
      {required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    final board = toMatrix(gameState["board"]);
    for (var i = 0; i < board.length; i++) {
      for (var j = 0; j < board[i].length; j++) {
        final piece = board[i][j];
        if (piece != null && piece.type == PieceType.king) {
          final targets =
              piece.type.possibleTargets(board, fromMatrixPosition(Pair(i, j)));
          if (targets.isEmpty) {
            return {"winner": piece.color.opposite};
          }
        }
      }
    }
    return null;
  }
}
