import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/draw_my_thing.dart';
import 'package:flutter_fire_engine/model/game_builder.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:flutter_fire_engine/page/lobby_widget.dart';

class DrawMyThingWidget extends StatefulWidget {
  const DrawMyThingWidget({super.key});

  @override
  State<DrawMyThingWidget> createState() => _DrawMyThingWidgetState();
}

class _DrawMyThingWidgetState extends State<DrawMyThingWidget> {
  late GameManager gameManager;
  final key = GlobalKey();
  final double size = 500;
  List<List<Offset>> lines = [];
  List<Offset> currentLine = [];
  int timerVal = -1;
  bool isOutOfBounds = false;
  final textController = TextEditingController();
  final scrollController = ScrollController();
  Timer? timer;
  RoomData<DrawMyThingGameState>? roomData;

  @override
  void initState() {
    super.initState();
    gameManager = GameManager.instance;
    gameManager.setOnGameEvent<DrawMyThingGameState>((event, gameState) {
      switch (event.payload["type"]) {
        case "guess":
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!scrollController.hasClients) return;
            scrollToBottom();
          });
          break;
        case "selectWord":
          timerVal = gameManager.getGameResponse({"type": "timerLimit"}).right;
          timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (gameManager.game.runtimeType != DrawMyThing ||
                !gameManager.hasRoom() ||
                roomData == null ||
                !roomData!.gameStarted ||
                roomData!.gameState!.selectingWord) {
              timer.cancel();
              return;
            }
            setState(() {
              timerVal--;
            });
            if (timerVal <= 0) {
              if (gameManager
                  .getGameResponse({"type": "isCurrentPlayer"}).right) {
                gameManager.sendGameEvent({"type": "turnChange"});
              }
              timer.cancel();
              return;
            }
          });
          lines.clear();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GameBuilder<DrawMyThingGameState>(
      builder: (context, roomData, gameManager) =>
          LobbyWidget(roomData: roomData, gameManager: gameManager),
      gameStartedBuilder: (context, roomData, gameState, gameManager) {
        this.roomData = roomData;
        if (gameManager.getGameResponse({"type": "isCurrentPlayer"}).right) {
          return _drawWidget(roomData.gameState!);
        }
        return _guessWidget(roomData.gameState!);
      },
    );
  }

  Widget _drawingImageWidget(List<List<Offset>> drawing) {
    return CustomPaint(
      key: key,
      painter: MyPainter(lines: drawing),
      size: Size(size, size),
    );
  }

  Widget _scoresWidget(Map<Player, int> scores) {
    return Text(
        "Scores — ${scores.entries.map((entry) => "${entry.key.name}: ${entry.value}").join(", ")}");
  }

  Widget _drawWidget(DrawMyThingGameState gameState) {
    final rescaledSize =
        min(MediaQuery.of(context).size.width * 3 / 4, size * 3 / 4);
    if (gameState.selectingWord) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
                _scoresWidget(gameState.scores),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      "Round ${gameState.roundCount + 1}/${gameManager.getGameResponse({
                        "type": "totalRoundCount"
                      }).right}"),
                ),
                const Text("Select a word:")
              ] +
              gameState.wordOptions
                  .map((e) => TextButton(
                      onPressed: () {
                        gameManager
                            .sendGameEvent({"type": "selectWord", "word": e});
                      },
                      child: Text(e)))
                  .toList(),
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Round ${gameState.roundCount + 1}/${gameManager.getGameResponse({
                    "type": "totalRoundCount"
                  }).right}",
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              "$timerVal",
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              "Word: ${gameState.currentWord}",
              style: const TextStyle(fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: rescaledSize,
                width: rescaledSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    FittedBox(
                      child: Listener(
                        onPointerDown: (event) {
                          setState(() {
                            currentLine = [];
                            lines.add(currentLine);
                          });
                        },
                        onPointerUp: (event) {
                          gameManager.sendGameEvent({
                            "type": "draw",
                            "line": gameManager.getGameResponse({
                              "type": "serializeLine",
                              "line": currentLine
                            }).right
                          });
                        },
                        onPointerMove: (event) {
                          setState(() {
                            final box = key.currentContext?.findRenderObject()
                                as RenderBox?;
                            if (box == null) return;
                            final position = box.globalToLocal(event.position);
                            if (position.dx < 0 ||
                                position.dx >= box.size.width ||
                                position.dy < 0 ||
                                position.dy >= box.size.height) {
                              if (!isOutOfBounds) {
                                gameManager.sendGameEvent({
                                  "type": "draw",
                                  "line": gameManager.getGameResponse({
                                    "type": "serializeLine",
                                    "line": currentLine
                                  }).right
                                });
                                currentLine = [];
                                lines.add(currentLine);
                                isOutOfBounds = true;
                              }
                            } else {
                              if ((position -
                                          (currentLine.lastOrNull ??
                                              Offset.zero))
                                      .distance >
                                  5) {
                                currentLine.add(position);
                              }
                              isOutOfBounds = false;
                            }
                          });
                        },
                        child: _drawingImageWidget(lines),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          if (lines.isEmpty) return;
                          lines.removeLast();
                          gameManager.sendGameEvent({"type": "undo"});
                        },
                        child: const Text("Undo")),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                  height: 150,
                  width: rescaledSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: gameState.currentGuesses
                              .expand((guess) => [
                                    Text("${guess.key.name}: ${guess.value}"),
                                    const Divider()
                                  ])
                              .toList()),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guessWidget(DrawMyThingGameState gameState) {
    final rescaledSize =
        min(MediaQuery.of(context).size.width * 2 / 3, size * 2 / 3);
    if (gameState.selectingWord) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _scoresWidget(gameState.scores),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                "Round ${gameState.roundCount + 1}/${gameManager.getGameResponse({
                  "type": "totalRoundCount"
                }).right}"),
          ),
          Text("Waiting for ${gameManager.getGameResponse({
                    "type": "getCurrentPlayer"
                  }).right.name} to select a word..."),
        ],
      ));
    }
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Round ${gameState.roundCount + 1}/${gameManager.getGameResponse({
                    "type": "totalRoundCount"
                  }).right}",
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              "$timerVal",
              style: const TextStyle(fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: rescaledSize,
                width: rescaledSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: FittedBox(
                  child: _drawingImageWidget(gameState.currentDrawing),
                ),
              ),
            ),
            Text(
              "Word: ${gameState.currentWord.characters.map((c) => isAlphanumeric(c) ? "_" : c).join(" ")}",
              style: const TextStyle(fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                  height: 200,
                  width: rescaledSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                          child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: gameState.currentGuesses
                                  .expand((guess) => [
                                        Text(
                                            "${guess.key.name}: ${guess.value}"),
                                        const Divider()
                                      ])
                                  .toList()),
                        ),
                      )),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: TextField(
                                controller: textController,
                                decoration: const InputDecoration(
                                    hintText: "Guess the word..."),
                                onSubmitted: (value) {
                                  gameManager.sendGameEvent(
                                      {"type": "guess", "word": value});
                                  textController.clear();
                                },
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }

  void scrollToBottom() {
    scrollController.animateTo(scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  bool isAlphanumeric(String s) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(s);
  }
}

class MyPainter extends CustomPainter {
  final List<List<Offset>> lines;

  const MyPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.black;
    lines.forEach((line) {
      for (var i = 0; i < line.length - 1; i++) {
        canvas.drawLine(line[i], line[i + 1], paint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
