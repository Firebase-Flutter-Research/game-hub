import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/pong.dart';
import 'package:flutter_fire_engine/game_engine/pong_objects.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:game_engine/game_engine.dart';

class PongWidget extends GameWidget {
  final RoomDataGameState<PongGameState> roomData;

  const PongWidget({super.key, required super.size, required this.roomData});

  @override
  void draw(Canvas canvas, GameStateManager manager) {
    final gameManager = GameManager.instance;

    if (!gameManager.hasRoom() || roomData.players.length != 2) return;

    final other = gameManager.getGameResponse({}).right as Player;
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 4,
    );
    final textSpanUp = TextSpan(
        text: roomData.gameState.scores[other].toString(), style: textStyle);
    final textPainterUp = TextPainter(
      text: textSpanUp,
      textDirection: TextDirection.ltr,
    );
    textPainterUp.layout();
    textPainterUp.paint(
        canvas,
        Offset(manager.canvasSize.width / 2 - textPainterUp.width / 2,
            manager.canvasSize.height / 4 - textPainterUp.height));
    final textSpanDown = TextSpan(
        text: roomData.gameState.scores[gameManager.player].toString(),
        style: textStyle);
    final textPainterDown = TextPainter(
      text: textSpanDown,
      textDirection: TextDirection.ltr,
    );
    textPainterDown.layout();
    textPainterDown.paint(
        canvas,
        Offset(manager.canvasSize.width / 2 - textPainterDown.width / 2,
            manager.canvasSize.height * 3 / 4 - textPainterDown.height));
  }

  @override
  void init(GameStateManager manager) {
    manager.addInstance(Wall(
        position: const Offset(0, 0),
        hitBox: HitBox(Offset(Wall.width, manager.canvasSize.height))));
    manager.addInstance(Wall(
        position: Offset(manager.canvasSize.width - Wall.width, 0),
        hitBox: HitBox(Offset(Wall.width, manager.canvasSize.height))));

    manager.addInstance(PlayerPaddle(
        position: Offset(manager.canvasSize.width / 2 - PlayerPaddle.length / 2,
            manager.canvasSize.height - 4)));

    manager.addInstance(EnemyPaddle(
        position:
            Offset(manager.canvasSize.width / 2 - PlayerPaddle.length / 2, 0)));
    manager.addInstance(EnemyBarrier(position: const Offset(0, 0)));

    final gameManager = GameManager.instance;

    manager.addInstance(Puck(
        direction:
            Offset(0, gameManager.player == roomData.players.first ? 1 : -1) *
                Puck.speed /
                5,
        roomData: roomData,
        position: Offset(manager.canvasSize.width / 2 - Puck.radius,
            manager.canvasSize.height / 2 - Puck.radius)));

    gameManager.setOnGameEvent<PongGameState>((event, gameState) {
      if (!gameManager.hasRoom() || roomData.players.length != 2) return;
      final puck = manager.getInstancesWhereType<Puck>().firstOrNull;
      if (gameState.lastHitter == gameManager.player) return;
      switch (event.payload["type"]) {
        case "hit":
          puck?.onHit(manager);
          break;
        case "miss":
          puck?.onMiss(manager);
          break;
      }
    });
  }

  @override
  void update(double deltaTime, GameStateManager manager) {
    manager.getInstancesWhereType<Puck>().firstOrNull?.roomData = roomData;
  }
}
