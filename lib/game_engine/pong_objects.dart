import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
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
  void update(GameStateManager manager) {}
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
  void update(GameStateManager manager) {
    if (manager.pointerDown && containsPoint(manager.pointerPosition)) {
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
  void update(GameStateManager manager) {
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
  void update(GameStateManager manager) {}
}

class Puck extends GameObject {
  static const speed = 4.0;

  Offset direction;
  final RoomData roomData;

  bool waiting = false;
  Offset contactPosition = Offset.zero;
  Offset contactDirection = Offset.zero;

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
  void init(GameStateManager manager) {}

  @override
  void update(GameStateManager manager) {
    final xCollisions =
        manager.getCollisions(this, position + direction.scale(1, 0));
    final yCollisions =
        manager.getCollisions(this, position + direction.scale(0, 1));

    if (xCollisions.whereType<Wall>().isNotEmpty) {
      direction = direction.scale(-1, 1);
    }

    final paddle = yCollisions.whereType<PlayerPaddle>().firstOrNull;
    if (paddle != null) {
      final relativeX = (position.dx +
              hitBox!.size.dx / 2 -
              paddle.position.dx -
              PlayerPaddle.length / 2) /
          PlayerPaddle.length *
          10;
      direction = normalize(Offset(relativeX, -1)) * speed;
    }

    // TODO: Remove this case, other player's device handles this
    final enemyPaddle = yCollisions.whereType<EnemyPaddle>().firstOrNull;
    if (enemyPaddle != null) {
      final relativeX = (position.dx +
              hitBox!.size.dx / 2 -
              enemyPaddle.position.dx -
              PlayerPaddle.length / 2) /
          PlayerPaddle.length *
          10;
      contactPosition = position;
      contactDirection = normalize(Offset(relativeX, 1)) * speed;
      if (!waiting) {
        Future.delayed(const Duration(milliseconds: 400), () {
          // TODO: This logic should happen when a Firebase response has been received
          position = contactPosition;
          direction = contactDirection;
          waiting = false;
        });
      }
    }

    final barrier = yCollisions.whereType<EnemyBarrier>().firstOrNull;
    if (barrier != null) {
      waiting = true;
      direction = Offset.zero;
      position = Offset(position.dx, PlayerPaddle.height);
    }

    position += direction;

    // TODO: Fix new ball direction to face the loser
    // TODO: Score when ball goes out of bounds
    if (position.dy < 0 || position.dy >= manager.canvasSize.height) {
      manager.removeInstance(instance: this);
      manager.addInstance(Puck(
          direction: const Offset(0, 1) * Puck.speed / 5,
          roomData: roomData,
          position: Offset(manager.canvasSize.width / 2 - 2,
              manager.canvasSize.height / 2 - 2)));
    }
  }

  static Offset normalize(Offset offset) {
    return offset / offset.distance;
  }
}
