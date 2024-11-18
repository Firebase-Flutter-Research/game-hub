import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/rock_paper_scissors.dart';
import 'package:flutter_fire_engine/model/game_builder.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:flutter_fire_engine/page/lobby_widget.dart';

class RockPaperScissorsPage extends StatelessWidget {
  // final RoomData roomData;

  const RockPaperScissorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GameBuilder<RockPaperScissorsGameState>(
        notStartedBuilder: (context, roomData, gameManager) =>
            LobbyWidget(roomData: roomData, gameManager: gameManager),
        gameStartedBuilder: (context, roomData, gameManager) {
          final index = roomData.players.indexOf(GameManager.instance.player);
          if (index != -1 && roomData.gameState.choices[index] == null) {
            return _gameWidget(context, roomData);
          }
          return const Center(child: Text("Waiting for the other player..."));
        });
  }
}

Widget _gameWidget(BuildContext context, RoomData roomData) {
  final gameManager = GameManager.instance;
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Make your choice..."),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: RockPaperScissorsChoice.values
              .map((choice) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () async {
                          await gameManager
                              .sendGameEvent({"choice": choice.key});
                        },
                        child: Center(
                            child: Text(
                          choice.icon,
                          style: const TextStyle(fontSize: 32),
                        )),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    ),
  );
}
