import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/connect_four.dart';
import 'package:flutter_fire_engine/logic/utils.dart';
import 'package:flutter_fire_engine/model/game_builder.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/page/lobby_widget.dart';

class ConnectFourPage extends StatelessWidget {
  const ConnectFourPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GameBuilder<ConnectFourGameState>(
        notStartedBuilder: (context, roomData, gameManager) =>
            LobbyWidget(roomData: roomData, gameManager: gameManager),
        gameStartedBuilder: (context, roomData, gameManager) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                "It is ${roomData.gameState.currentPlayer < roomData.players.length ? roomData.players[roomData.gameState.currentPlayer].name : "No one"}'s turn"),
            _boardWidget(roomData.gameState),
          ]));
        });
  }

  Widget _boardWidget(ConnectFourGameState gameState) {
    final gameManager = GameManager.instance;
    double size = 40;
    final board = List<int>.from(gameState.board);
    Widget buttons = Row(
        mainAxisSize: MainAxisSize.min,
        children: joinWidgets(
            List.generate(
                ConnectFour.width,
                (index) => SizedBox(
                      height: size,
                      width: size,
                      child: ElevatedButton(
                          onPressed: () async {
                            await gameManager
                                .sendGameEvent({"position": index});
                          },
                          child: const Text("")),
                    )),
            SizedBox(
                height: size, child: const VerticalDivider(thickness: 2))));
    Widget grid = Row(
      mainAxisSize: MainAxisSize.min,
      children: joinWidgets(
          List.generate(
              ConnectFour.width,
              (j) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                        ConnectFour.height,
                        (i) => SizedBox(
                            width: size,
                            height: size,
                            child: board[i * ConnectFour.width + j] == -1
                                ? const Center(child: Text(""))
                                : Center(
                                    child: Text("●",
                                        style: TextStyle(
                                            fontSize: 32,
                                            color: [Colors.red, Colors.yellow][
                                                board[i * ConnectFour.width +
                                                    j]]))))),
                  )),
          SizedBox(
              height: size * ConnectFour.height,
              child: const VerticalDivider(thickness: 2))),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        grid,
        SizedBox(
            width: size * (ConnectFour.width + 2.5),
            child: const Divider(thickness: 2)),
        buttons
      ],
    );
  }
}
