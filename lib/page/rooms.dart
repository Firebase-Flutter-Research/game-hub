import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  static const int minutesBeforeHide = 15;
  @override
  Widget build(BuildContext context) {
    final gameManager = GameManager.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Room"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          TextField(
            controller: TextEditingController(text: gameManager.player.name),
            decoration: const InputDecoration(labelText: "Player Name"),
            onChanged: (value) {
              gameManager.setPlayerName(value.trim());
            },
          ),
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: StreamBuilder(
                    stream: gameManager.getRooms(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container();
                      }
                      return Column(
                          children: snapshot.data!.docs
                              .where((doc) =>
                                  (doc["lastUpdateTimestamp"] == null ||
                                      Timestamp.now()
                                              .toDate()
                                              .difference(
                                                  doc["lastUpdateTimestamp"]
                                                      .toDate())
                                              .inMinutes <
                                          minutesBeforeHide) &&
                                  !doc["gameStarted"] &&
                                  doc["playerCount"] <
                                      gameManager.game!.playerLimit)
                              .map((doc) => _roomListItem(context, doc))
                              .toList());
                    },
                  ))),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                  child: ElevatedButton(
                onPressed: () async {
                  if (await gameManager.createRoom()) {
                    Navigator.of(context).pushNamed("/inGame");
                  }
                },
                child: const Text("Create Room"),
              ))
            ],
          ),
        ]),
      ),
    );
  }

  Widget _roomListItem(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) {
    final gameManager = GameManager.instance;
    if (doc.data() == null || !gameManager.hasGame()) return Container();
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () async {
                    if (await gameManager.joinRoom(doc)) {
                      Navigator.of(context).pushNamed("/inGame");
                    }
                  },
                  child: Text(
                      "${doc.data()?["host"]["name"]}'s Room (${doc.data()?["playerCount"]}/${gameManager.game!.playerLimit})")))
        ],
      ),
    );
  }
}
