import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/firebase_room_data.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/rooms_builder.dart';

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
                  child: RoomsBuilder(
                    game: gameManager.game!,
                    builder: (context, roomDataList) {
                      return Column(
                        children: roomDataList
                            .where((data) =>
                                Timestamp.now()
                                        .toDate()
                                        .difference(
                                            data.lastUpdateTimestamp.toDate())
                                        .inMinutes <
                                    minutesBeforeHide &&
                                !data.gameStarted &&
                                data.playerCount < data.game.playerLimit)
                            .map((data) => _roomListItem(context, data))
                            .toList(),
                      );
                    },
                    loadingBuilder: (context) => Container(),
                  ))),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                  child: ElevatedButton(
                onPressed: () async {
                  final password = await showDialog<String?>(
                      context: context,
                      useRootNavigator: false,
                      builder: (context) {
                        final controller = TextEditingController();
                        sendPassword() =>
                            Navigator.of(context).pop(controller.text.trim());
                        return AlertDialog(
                          title: const Text("Create Room"),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: const InputDecoration(
                                hintText: "Add password?"),
                            onSubmitted: (_) => sendPassword(),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Cancel")),
                            TextButton(
                                onPressed: sendPassword,
                                child: const Text("Create"))
                          ],
                        );
                      });
                  if (password != null) {
                    if (await gameManager
                        .createRoom(password.isNotEmpty ? password : null)) {
                      Navigator.of(context).pushNamed("/inGame");
                    }
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

  Widget _roomListItem(BuildContext context, FirebaseRoomData roomData) {
    final gameManager = GameManager.instance;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () async {
                    String? password;
                    if (roomData.password != null) {
                      password = await showDialog<String?>(
                          context: context,
                          useRootNavigator: false,
                          builder: (context) {
                            final controller = TextEditingController();
                            sendPassword() => Navigator.of(context)
                                .pop(controller.text.trim());
                            return AlertDialog(
                              title: const Text("Join Room"),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                onSubmitted: (_) => sendPassword(),
                                decoration: const InputDecoration(
                                    hintText: "Enter password..."),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("Cancel")),
                                TextButton(
                                    onPressed: sendPassword,
                                    child: const Text("Join"))
                              ],
                            );
                          });
                      if (password == null) {
                        return;
                      }
                    }
                    if (await gameManager.joinRoom(
                        roomData.document, password)) {
                      Navigator.of(context).pushNamed("/inGame");
                    } else {
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            content: Text("Password is incorrect")));
                    }
                  },
                  child: Stack(
                    alignment: AlignmentDirectional.centerEnd,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                  "${roomData.host.name}'s Room (${roomData.playerCount}/${roomData.game.playerLimit})"),
                            ),
                          ),
                        ],
                      ),
                      if (roomData.password != null)
                        const Icon(
                          Icons.lock,
                          color: Colors.black87,
                        )
                    ],
                  )))
        ],
      ),
    );
  }
}
