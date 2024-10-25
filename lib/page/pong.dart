import "package:flutter/material.dart";
import "package:flutter_fire_engine/game_engine/pong_widget.dart";
import "package:flutter_fire_engine/model/room.dart";

class PongPage extends StatelessWidget {
  final RoomData roomData;

  const PongPage({super.key, required this.roomData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: PongWidget(size: const Size(75, 100), roomData: roomData));
  }
}
