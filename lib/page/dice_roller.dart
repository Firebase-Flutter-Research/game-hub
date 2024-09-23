import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';

class DiceRollerPage extends StatelessWidget {
  final RoomData roomData;

  const DiceRollerPage({super.key, required this.roomData});

  @override
  Widget build(BuildContext context) {
    GameManager.instance.setOnGameEvent((event, gameState) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title:
                  Text("${event.author.name} rolled a ${gameState["roll"]}")));
    });
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              "It is ${roomData.gameState!["currentPlayer"] < roomData.players.length ? roomData.players[roomData.gameState!["currentPlayer"]].name : "No one"}'s turn to roll"),
          SizedBox(
            width: 150,
            height: 150,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () {
                    GameManager.instance.sendGameEvent({});
                  },
                  child: const Text("🎲", style: TextStyle(fontSize: 36))),
            ),
          ),
        ],
      ),
    );
  }
}
