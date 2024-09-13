import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/page/tic_tac_toe.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    GameManager.instance.setGame(TicTacToe());
  }

  @override
  Widget build(BuildContext context) {
    final roomManager = GameManager.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Room"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          TextField(
            controller: TextEditingController(text: roomManager.player.name),
            decoration: const InputDecoration(labelText: "Player Name"),
            onChanged: (value) {
              roomManager.setPlayerName(value);
            },
          ),
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: StreamBuilder(
                    stream: roomManager.getRooms(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container();
                      }
                      return Column(
                          children: snapshot.data!.docs
                              .mapIndexed(
                                  (i, doc) => _roomListItem(context, i, doc))
                              .toList());
                    },
                  ))),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                  child: ElevatedButton(
                onPressed: () async {
                  if (await roomManager.createRoom()) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => TicTacToePage()));
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
      BuildContext context, int i, DocumentSnapshot<Map<String, dynamic>> doc) {
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
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TicTacToePage()));
                    }
                  },
                  child: Text(
                      "${doc.data()?["host"]["name"]}'s Room (${doc.data()?["playerCount"]}/${gameManager.game!.playerLimit})")))
        ],
      ),
    );
  }
}
