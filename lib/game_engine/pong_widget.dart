import 'dart:ui';

import 'package:flutter_fire_engine/game_engine/pong_objects.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:game_engine/game_engine.dart';

class PongWidget extends GameWidget {
  final RoomData roomData;

  const PongWidget({super.key, required super.size, required this.roomData});

  @override
  void draw(Canvas canvas, GameStateManager manager) {}

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

    manager.addInstance(Puck(
        direction: const Offset(0, 1) * Puck.speed / 5,
        roomData: roomData,
        position: Offset(manager.canvasSize.width / 2 - 2,
            manager.canvasSize.height / 2 - 2)));
  }

  @override
  void update(GameStateManager manager) {}
}
