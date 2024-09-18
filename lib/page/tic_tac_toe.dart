import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/logic/utils.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:collection/collection.dart';

class TicTacToePage extends StatelessWidget {
  final RoomData roomData;

  const TicTacToePage({super.key, required this.roomData});

  @override
  Widget build(BuildContext context) {
    return _gameWidget(context, roomData);
  }
}

Widget _gameWidget(BuildContext context, RoomData roomData) {
  return Center(
      child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
          "It is ${roomData.gameState!["currentPlayer"] < roomData.players.length ? roomData.players[roomData.gameState!["currentPlayer"]].name : "No one"}'s turn"),
      _tableWidget(context, roomData),
    ],
  ));
}

Widget _tableWidget(BuildContext context, RoomData roomData) {
  final gameManager = GameManager.instance;
  List<IconData> icons = [Icons.close, Icons.circle_outlined];
  List<Row> rows = [];
  for (int i = 0; i < 9; i += 3) {
    rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: joinWidgets(
            List<int>.from(roomData.gameState!["board"])
                .sublist(i, i + 3)
                .mapIndexed((j, e) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: TextButton(
                            onPressed: () async {
                              await gameManager
                                  .sendGameEvent({"position": i + j});
                            },
                            child: e == -1
                                ? const Text("")
                                : Icon(icons[e], size: 48)),
                      ),
                    ))
                .toList(),
            const SizedBox(
                height: 100, child: VerticalDivider(thickness: 2, width: 4)))));
  }
  return Column(
      children: joinWidgets(
          rows,
          const SizedBox(
              width: (100 + 4 * 2) * 3 + 4 * 2,
              child: Divider(thickness: 2, height: 4))));
}
