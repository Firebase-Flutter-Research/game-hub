import "package:flutter/material.dart";
import "package:flutter_fire_engine/example/pong.dart";
import "package:flutter_fire_engine/game_engine/pong_widget.dart";
import "package:flutter_fire_engine/model/game_builder.dart";
import "package:flutter_fire_engine/page/lobby_widget.dart";

class PongPage extends StatelessWidget {
  const PongPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GameBuilder<PongGameState>(
      notStartedBuilder: (context, roomData, gameManager) =>
          LobbyWidget(roomData: roomData, gameManager: gameManager),
      gameStartedBuilder: (context, roomData, gameManager) => SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: PongWidget(size: const Size(75, 100), roomData: roomData)),
    );
  }
}
