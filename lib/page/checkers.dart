import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/checkers.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:pair/pair.dart';

class CheckersPage extends StatefulWidget {
  final RoomData roomData;

  const CheckersPage({super.key, required this.roomData});

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
  }

  @override
  Widget build(BuildContext context) {
    roomData = widget.roomData;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              "It is ${roomData.gameState!["currentPlayer"] < roomData.players.length ? roomData.players[roomData.gameState!["currentPlayer"]].name : "No one"}'s turn"),
          _checkerboardWidget(context, roomData),
        ],
      ),
    );
  }

  Widget _checkerboardWidget(BuildContext context, RoomData roomData) {
    final board = Checkers.toBoard(roomData.gameState!["board"]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: board
          .mapIndexed((i, row) => Row(
                mainAxisSize: MainAxisSize.min,
                children: row
                    .mapIndexed(
                        (j, piece) => _checkersTileWidget(i, j, piece, board))
                    .toList(),
              ))
          .toList(),
    );
  }

  Widget _checkersTileWidget(
      int i, int j, CheckersPiece? piece, List<List<CheckersPiece?>> board) {
    Widget tileChild;
    Color pieceColor;
    double tileWidth = min(MediaQuery.sizeOf(context).width / 9, 50);

    if (piece != null) {
      pieceColor = Checkers.getIndexFromPiece(piece) == 0
          ? Colors.deepPurple
          : Colors.red[400]!;
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
        if (roomData.players[roomData.gameState!["currentPlayer"]] !=
            gameManager.player) {
          return;
        }
        if (piece != null &&
            roomData.players.indexOf(gameManager.player) ==
                Checkers.getIndexFromPiece(piece)) {
          setState(() {
            possibleRoutes = piece.possibleRoutes(Pair(i, j), board);
          });
        } else {
          if (possibleRoutes != null) {
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