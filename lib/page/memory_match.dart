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

  Widget _cardWidgetBase(Color color, [Widget? child]) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 70,
            height: 135,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                    blurRadius: 5.0, spreadRadius: 1.0, color: Colors.black87)
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child:
                      Container(color: Colors.white, height: 50, child: child),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _cardWidget(MemoryCard card, [void Function()? callback]) {
    String symbol = "";
    Color color = Colors.lightBlue;
    bool visibility = true;
    if (card.isFlipped()) {
      symbol = card.symbol;
      color = Colors.green;
    }
    if (card.playerMatched != null) {
      visibility = false;
    }
    return Visibility(
      child: GestureDetector(
          onTap: callback,
          child: _cardWidgetBase(
              color,
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(symbol,
                    style: TextStyle(color: Colors.grey[800]!, fontSize: 28),
                    textDirection: TextDirection.ltr)
              ]))),
      visible: visibility,
    );
  }

  Widget _tableWidget(
      BuildContext context, RoomData roomData, GameManager gameManager) {
    List<Row> rows = [];
    for (int i = 0; i < 30; i += 6) {
      rows.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: List<MemoryCard>.from(roomData.gameState!["layout"])
              .sublist(i, i + 6)
              .mapIndexed((j, e) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SizedBox(
                      width: 70,
                      height: 135,
                      child: _cardWidget(roomData.gameState!["layout"][i + j],
                          () async {
                        await gameManager.sendGameEvent({"position": i + j});
                      }),
                    ),
                  ))
              .toList()));
    }
    return Column(children: rows);
  }
}
