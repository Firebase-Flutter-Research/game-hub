import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/checkers.dart';
import 'package:flutter_fire_engine/model/game_builder.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:flutter_fire_engine/page/lobby_widget.dart';
import 'package:pair/pair.dart';

class CheckersPage extends StatefulWidget {
  const CheckersPage({super.key});

  @override
  State<CheckersPage> createState() => _CheckersPageState();
}

class _CheckersPageState extends State<CheckersPage> {
  late GameManager gameManager;
  List<CheckersRoute>? possibleRoutes;
  late RoomData roomData;

  @override
  void initState() {
    super.initState();
    gameManager = GameManager.instance;

    gameManager.setOnGameResponseFailure((failure) {
      if (!context.mounted) return;
      if (failure.message != null) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message!)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameBuilder<CheckersGameState>(
        notStartedBuilder: (context, roomData, gameManager) =>
            LobbyWidget(roomData: roomData, gameManager: gameManager),
        gameStartedBuilder: (context, roomData, gameManager) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "It is ${roomData.gameState.currentPlayer < roomData.players.length ? roomData.players[roomData.gameState.currentPlayer].name : "No one"}'s turn"),
                _checkerboardWidget(context),
              ],
            ),
          );
        });
  }

  Widget _checkerboardWidget(BuildContext context) {
    final board = List<List<CheckersPiece?>>.from(gameManager
        .getGameResponse({"type": CheckersRequestType.getBoard}).right);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: board
          .mapIndexed((i, row) => Row(
                mainAxisSize: MainAxisSize.min,
                children: row
                    .mapIndexed((j, piece) => _checkersTileWidget(i, j, piece))
                    .toList(),
              ))
          .toList(),
    );
  }

  Widget _checkersTileWidget(int i, int j, CheckersPiece? piece) {
    Widget tileChild;
    Color pieceColor;
    double tileWidth = min(MediaQuery.sizeOf(context).width / 9, 50);

    if (piece != null) {
      pieceColor = gameManager.getGameResponse(
          {"type": CheckersRequestType.getPieceColor, "piece": piece}).right;
      tileChild = FractionallySizedBox(
        heightFactor: 0.75,
        widthFactor: 0.75,
        child: Container(
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: pieceColor),
            child: Center(
                child: Text(
              piece.isKing ? "♕" : "",
              style: const TextStyle(fontSize: 30, color: Colors.black54),
            ))),
      );
    } else if (possibleRoutes?.any((route) => route.end == Pair(i, j)) ??
        false) {
      tileChild = FractionallySizedBox(
        heightFactor: 0.5,
        widthFactor: 0.5,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueGrey,
          ),
        ),
      );
    } else {
      tileChild = Container();
    }

    return GestureDetector(
      onTap: () {
        if (!gameManager.getGameResponse(
            {"type": CheckersRequestType.isCurrentPlayer}).isRight) {
          return;
        }
        if (possibleRoutes == null) {
          setState(() {
            final routesResponse = gameManager.getGameResponse({
              "type": CheckersRequestType.getPossibleRoutes,
              "position": Pair(i, j)
            });
            if (routesResponse.isRight) {
              possibleRoutes = routesResponse.right;
            }
          });
        } else {
          if (piece == null) {
            CheckersRoute? route = possibleRoutes
                ?.where((route) => route.end == Pair(i, j))
                .firstOrNull;
            if (route != null) {
              gameManager.sendGameEvent({
                "route": route.toJson(),
              });
            }
            setState(() {
              possibleRoutes = null;
            });
          } else if (possibleRoutes?.first.start == Pair(i, j) ||
              !gameManager.getGameResponse({
                "type": CheckersRequestType.playerOwnsPiece,
                "piece": piece
              }).right) {
            setState(() {
              possibleRoutes = null;
            });
          } else {
            setState(() {
              final routesResponse = gameManager.getGameResponse({
                "type": CheckersRequestType.getPossibleRoutes,
                "position": Pair(i, j)
              });
              if (routesResponse.isRight) {
                possibleRoutes = routesResponse.right;
              } else {
                possibleRoutes = null;
              }
            });
          }
        }
      },
      child: Container(
        color: ((i + j) % 2 == 0) ? Colors.red[600] : Colors.black87,
        height: tileWidth,
        width: tileWidth,
        child: tileChild,
      ),
    );
  }
}
