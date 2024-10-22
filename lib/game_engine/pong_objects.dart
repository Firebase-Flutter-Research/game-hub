import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:game_engine/game_engine.dart';

class Wall extends GameObject {
  static const width = 4.0;

  Wall({required super.position, required super.hitBox});

  @override
  void draw(Canvas canvas, GameStateManager manager) {
    canvas.drawRect(
        Rect.fromLTWH(
            position.dx, position.dy, hitBox!.size.dx, hitBox!.size.dy),
        Paint()..color = Colors.grey[500]!);
  }

  @override
  void init(GameStateManager manager) {}

  @override
  void update(double deltaTime, GameStateManager manager) {}
}

class PlayerPaddle extends GameObject {
  static const length = 20.0;
  static const height = 4.0;

  PlayerPaddle(
      {required super.position,
      super.hitBox = const HitBox(Offset(length, height))});

  bool grabbed = false;

  @override
  void draw(Canvas canvas, GameStateManager manager) {
    canvas.drawRect(
        Rect.fromLTWH(
            position.dx, position.dy, hitBox!.size.dx, hitBox!.size.dy),
        Paint()..color = Colors.grey[800]!);
  }

  @override
  void init(GameStateManager manager) {}

  @override
  void update(double deltaTime, GameStateManager manager) {
    if (manager.pointerDown) {
      grabbed = true;
    }
    if (grabbed) {
      if (manager.pointerUp) grabbed = false;
      position = Offset(
          min(max(manager.pointerPosition.dx, Wall.width + length / 2),
                  manager.canvasSize.width - Wall.width - length / 2) -
              length / 2,
          position.dy);
    }
  }
}

class EnemyPaddle extends GameObject {
  static const maxSpeed = 10;

  EnemyPaddle(
      {required super.position,
      super.hitBox =
          const HitBox(Offset(PlayerPaddle.length, PlayerPaddle.height))});

  @override
  void draw(Canvas canvas, GameStateManager manager) {
    canvas.drawRect(
        Rect.fromLTWH(
            position.dx, position.dy, hitBox!.size.dx, hitBox!.size.dy),
        Paint()..color = Colors.grey[700]!);
  }

  @override
  void init(GameStateManager manager) {}

  @override
  void update(double deltaTime, GameStateManager manager) {
    final puck = manager.getInstancesWhereType<Puck>().firstOrNull;
    if (puck != null) {
      position = Offset(
          min(
                  max(puck.position.dx + puck.hitBox!.size.dx / 2,
                      Wall.width + PlayerPaddle.length / 2),
                  manager.canvasSize.width -
                      Wall.width -
                      PlayerPaddle.length / 2) -
              PlayerPaddle.length / 2,
          position.dy);
    }
  }
}

class EnemyBarrier extends GameObject {
  EnemyBarrier(
      {required super.position,
      super.hitBox = const HitBox(Offset(100, PlayerPaddle.height))});

  @override
  void draw(Canvas canvas, GameStateManager manager) {}

  @override
  void init(GameStateManager manager) {}

  @override
  void update(double deltaTime, GameStateManager manager) {}
}

class Puck extends GameObject {
  static const speed = 200.0;
  static const radius = 2.0;

  Offset direction;
  RoomData roomData;

  bool waiting = false;

  late GameManager gameManager;

  Puck(
      {required this.direction,
      required this.roomData,
      required super.position,
      super.hitBox = const HitBox(Offset(4, 4))});

  @override
  void draw(Canvas canvas, GameStateManager manager) {
    final offset = hitBox!.size / 2;
    canvas.drawCircle(
        position + offset, offset.dx, Paint()..color = Colors.black);
  }

  @override
  void init(GameStateManager manager) {
    gameManager = GameManager.instance;
  }

  void onHit(GameStateManager manager) {
    final other = gameManager.getGameResponse({}).right as Player;
    final contactPosition = roomData.gameState!["positions"][other] as Offset;
    final contactDirection = roomData.gameState!["directions"][other] as Offset;
    position = Offset(manager.canvasSize.width, manager.canvasSize.height) -
        contactPosition -
        const Offset(radius, radius);
    direction = -contactDirection;
    waiting = false;
  }

  void onMiss(GameStateManager manager) {
    manager.removeInstance(instance: this);
    manager.addInstance(Puck(
        direction: const Offset(0, -1) * Puck.speed / 5,
        roomData: roomData,
        position: Offset(manager.canvasSize.width / 2 - radius,
            manager.canvasSize.height / 2 - radius)));
    waiting = false;
  }

  @override
  void update(double deltaTime, GameStateManager manager) {
    if (!gameManager.hasRoom() || roomData.players.length != 2) return;

    final xCollisions = manager.getCollisions(
        this, position + direction.scale(1, 0) * deltaTime);
    final yCollisions = manager.getCollisions(
        this, position + direction.scale(0, 1) * deltaTime);

    if (xCollisions.whereType<Wall>().isNotEmpty) {
      direction = direction.scale(-1, 1);
    }

    final paddle = yCollisions.whereType<PlayerPaddle>().firstOrNull;
    if (paddle != null && direction.dy > 0) {
      final relativeX = (position.dx +
              hitBox!.size.dx / 2 -
              paddle.position.dx -
              PlayerPaddle.length / 2) /
          PlayerPaddle.length *
          5;
      direction = normalize(Offset(relativeX, -1)) * speed;
      gameManager.sendGameEvent({
        "type": "hit",
        "px": position.dx + radius,
        "py": position.dy + radius,
        "dx": direction.dx,
        "dy": direction.dy
      });
    }

    final barrier = yCollisions.whereType<EnemyBarrier>().firstOrNull;
    if (barrier != null && direction.dy < 0) {
      waiting = true;
      direction = Offset.zero;
      position = Offset(position.dx, PlayerPaddle.height);
    }

    position += direction * deltaTime;

    if (position.dy > manager.canvasSize.height) {
      gameManager.sendGameEvent({"type": "miss"});
      manager.removeInstance(instance: this);
      manager.addInstance(Puck(
          direction: const Offset(0, 1) * Puck.speed / 5,
          roomData: roomData,
          position: Offset(manager.canvasSize.width / 2 - radius,
              manager.canvasSize.height / 2 - radius)));
    }
  }

  static Offset normalize(Offset offset) {
    return offset / offset.distance;
  }
}
