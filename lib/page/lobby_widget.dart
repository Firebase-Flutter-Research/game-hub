import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';

class LobbyWidget extends StatelessWidget {
  final RoomData roomData;
  final GameManager gameManager;

  const LobbyWidget(
      {super.key, required this.roomData, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!roomData.hasRequiredPlayers)
            Text(
                "Waiting for more players... (${roomData.players.length}/${roomData.game.playerLimit})"),
          if (roomData.hasRequiredPlayers)
            Column(
              children: [
                const Text("Player requirement has been met."),
                if (gameManager.player == roomData.host)
                  TextButton(
                      onPressed: () {
                        gameManager.startGame();
                      },
                      child: const Text("Start")),
                if (gameManager.player != roomData.host)
                  const Text("Waiting for host to start..."),
              ],
            )
        ],
      ),
    );
  }
}
