import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/memory_match.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';

class MemoryMatchPage extends StatelessWidget {
  final RoomData roomData;

  const MemoryMatchPage({super.key, required this.roomData});

  @override
  Widget build(BuildContext context) {
    final gameManager = GameManager.instance;
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            "It is ${roomData.gameState!["currentPlayer"] < roomData.players.length ? roomData.players[roomData.gameState!["currentPlayer"]].name : "No one"}'s turn"),
        _tableWidget(context, roomData, gameManager),
      ],
    ));
  }

  Widget _cardWidgetBase(Color color, double size, [Widget? child]) {
    return Padding(
        padding: EdgeInsets.all(size / 20),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              boxShadow: const [
                BoxShadow(
                    blurRadius: 5.0, spreadRadius: 1.0, color: Colors.black87)
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.all(size / 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                      color: Colors.white, height: size / 2.5, child: child),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _cardWidget(MemoryCard card, double size,
      [void Function()? callback]) {
    String symbol = "";
    Color color = Colors.lightBlue;
    bool visibility = card.playerMatched == null;
    if (card.isFlipped()) {
      symbol = card.symbol;
      color = Colors.green;
    }
    return Visibility(
      visible: visibility,
      child: GestureDetector(
          onTap: callback,
          child: _cardWidgetBase(
              color,
              size,
              Text(symbol,
                  style:
                      TextStyle(color: Colors.grey[800]!, fontSize: size / 3),
                  textDirection: TextDirection.ltr))),
    );
  }

  Widget _tableWidget(
      BuildContext context, RoomData roomData, GameManager gameManager) {
    List<Row> rows = [];
    double screenWidth = MediaQuery.sizeOf(context).width;
    double screenHeight = MediaQuery.sizeOf(context).height;
    double cardSize = min(screenWidth / 7, screenHeight / 9);
    int numberOfColumns = sqrt(MemoryMatch.numberOfPairs * 2).toInt();
    for (int i = 0; i < MemoryMatch.numberOfPairs * 2; i += numberOfColumns) {
      rows.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: List<MemoryCard>.from(roomData.gameState!["layout"])
              .sublist(i, i + numberOfColumns)
              .mapIndexed((j, e) => Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: SizedBox(
                      width: cardSize,
                      height: cardSize,
                      child: _cardWidget(
                          roomData.gameState!["layout"][i + j], cardSize,
                          () async {
                        if (roomData.gameState!["currentlyFlipped"].length <
                            2) {
                          await gameManager.sendGameEvent({"position": i + j});
                          if (roomData.gameState!["currentlyFlipped"].length ==
                              2) {
                            Timer(const Duration(seconds: 1, milliseconds: 500),
                                () async {
                              await gameManager.sendGameEvent({"position": -1});
                            });
                          }
                        }
                      }),
                    ),
                  ))
              .toList()));
    }
    return Column(children: rows);
  }
}
