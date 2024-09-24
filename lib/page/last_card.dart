import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/last_card.dart';
import 'package:flutter_fire_engine/logic/utils.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';

class LastCardPage extends StatelessWidget {
  final RoomData roomData;

  const LastCardPage({super.key, required this.roomData});

  @override
  Widget build(BuildContext context) {
    final gameManager = GameManager.instance;
    final currentPlayer =
        roomData.players[roomData.gameState!["currentPlayer"]];
    return Column(
      children: [
        const SizedBox(height: 100),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: joinWidgets(
              getPlayersFromView(roomData.players, gameManager.player)
                  .map((p) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p.name,
                              style: TextStyle(
                                  fontWeight: p == currentPlayer
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16)),
                          Text(
                              "x${roomData.gameState!["playerCards"][p].length}"),
                        ],
                      ))
                  .toList(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(roomData.gameState!["direction"] > 0 ? "⟶" : "⟵",
                    style: const TextStyle(fontSize: 16)),
              )),
        ),
        Expanded(
            child: Center(
                child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cardWidget(roomData.gameState!["playedCards"].last),
            GestureDetector(
                onTap: () async {
                  await gameManager.sendGameEvent({"isDraw": true});
                },
                child: _cardWidgetBase(Colors.grey[800]!))
          ],
        ))),
        Text("You (${gameManager.player.name})",
            style: TextStyle(
                fontWeight: gameManager.player == currentPlayer
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 16)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List<LastCardCard>.from(
                      roomData.gameState!["playerCards"][gameManager.player])
                  .map((LastCardCard card) => _cardWidget(card, () async {
                        String? color;
                        if (LastCardType.fromValue(card.value).isWild) {
                          color = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                  title: const Text("Choose"),
                                  content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: LastCardColor.values
                                          .map((c) => TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(c.key);
                                              },
                                              child: Text(
                                                c.key,
                                                style:
                                                    TextStyle(color: c.color),
                                              )))
                                          .toList())));
                          if (color == null) return;
                        }
                        await gameManager.sendGameEvent({
                          "isPlace": true,
                          "card": card.toJson(),
                          "color": color
                        });
                      }))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

Widget _cardWidgetBase(Color color, [Widget? child]) {
  return Padding(
      padding: const EdgeInsets.all(8),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 100,
          height: 150,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(blurRadius: 5.0, spreadRadius: 1.0, color: Colors.black)
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              color: color,
              child: Align(
                alignment: Alignment.center,
                child: Container(color: Colors.white, height: 50, child: child),
              ),
            ),
          ),
        ),
      ));
}

Widget _cardWidget(LastCardCard card, [void Function()? callback]) {
  return GestureDetector(
      onTap: callback,
      child: _cardWidgetBase(
          card.color?.color ?? Colors.grey[800]!,
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(card.value.text,
                style: TextStyle(color: Colors.grey[800]!, fontSize: 28),
                textDirection: TextDirection.ltr)
          ])));
}

List<Player> getPlayersFromView(List<Player> players, Player player) {
  int index = players.indexOf(player);
  if (index == -1) return [];
  if (index == 0) return players.sublist(1, players.length);
  if (index == players.length - 1) {
    return players.sublist(0, players.length - 1);
  }
  return players.sublist(index + 1, players.length) + players.sublist(0, index);
}
