import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';

class GameBuilder<T extends GameState> extends StatelessWidget {
  final GameManager? gameManager;
  final Widget Function(BuildContext, RoomData<T>, GameManager) builder;
  final Widget Function(BuildContext, RoomData<T>, T, GameManager)?
      gameStartedBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const GameBuilder(
      {super.key,
      this.gameManager,
      required this.builder,
      this.gameStartedBuilder,
      this.loadingBuilder,
      this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    GameManager gameManager = this.gameManager ?? GameManager.instance;
    return StreamBuilder(
        stream: gameManager.roomDataStream,
        builder: (context, snapshot) {
          const placeholder = Placeholder();
          if (snapshot.hasError) {
            if (errorBuilder != null) {
              return errorBuilder!(
                  context, snapshot.error!, snapshot.stackTrace);
            }
            return placeholder;
          }
          if (!snapshot.hasData) {
            if (loadingBuilder != null) {
              return loadingBuilder!(context);
            }
            return placeholder;
          }
          final roomData = snapshot.data!.cast<T>();
          if (roomData.gameStarted && gameStartedBuilder != null) {
            return gameStartedBuilder!(
                context, roomData, roomData.gameState!, gameManager);
          }
          return builder(context, roomData, gameManager);
        });
  }
}
