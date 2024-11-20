import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:flutter_fire_engine/logic/utils.dart';
import 'package:fire_game_infra/fire_game_infra.dart';
import 'package:collection/collection.dart';
import 'package:flutter_fire_engine/page/lobby_widget.dart';

class TicTacToePage extends StatelessWidget {
  const TicTacToePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GameBuilder<TicTacToeGameState>(
      notStartedBuilder: (context, roomData, gameManager) =>
          LobbyWidget(roomData: roomData, gameManager: gameManager),
      gameStartedBuilder: (context, roomData, gameManager) {
        return Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "It is ${roomData.gameState.currentPlayer < roomData.players.length ? roomData.players[roomData.gameState.currentPlayer].name : "No one"}'s turn"),
            _tableWidget(context, roomData.gameState),
          ],
        ));
      },
    );
  }
}

Widget _tableWidget(BuildContext context, TicTacToeGameState gameState) {
  final gameManager = GameManager.instance;
  List<IconData> icons = [Icons.close, Icons.circle_outlined];
  List<Row> rows = [];
  for (int i = 0; i < 9; i += 3) {
    rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: joinWidgets(
            gameState.board
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
