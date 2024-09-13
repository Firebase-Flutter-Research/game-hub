import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> {
  late GameManager gameManager;

  @override
  void initState() {
    super.initState();
    gameManager = GameManager.instance;
    gameManager.setOnLeave(() {
      Navigator.of(context).pop();
    });
    gameManager.setOnGameStop((log) async {
      if (log == null) return;
      showDialog(
          context: context,
          useRootNavigator: true,
          builder: (context) => AlertDialog(
              title: Text(
                  log["draw"] ? "It's a draw!" : "${log['winnerName']} won!")));
    });
    gameManager.setOnEventFailure((failure) {
      if (failure.message != null) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message!)));
      }
    });
    gameManager.setOnPlayerJoin((player) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text("${player.name} joined the room")));
    });
    gameManager.setOnPlayerLeave((player) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("${player.name} left the room")));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (popped) {
        if (popped) return;
        gameManager.leaveRoom();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("In-game"),
        ),
        body: StreamBuilder(
            stream: gameManager.roomDataStream,
            builder: (context, snapshot) {
              if (snapshot.data == null || !context.mounted) return Container();
              final roomData = snapshot.data!;
              if (!roomData.gameStarted) return _lobbyWidget(context, roomData);
              return _gameWidget(context, roomData);
            }),
      ),
    );
  }

  Widget _lobbyWidget(BuildContext context, RoomData roomData) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!roomData.hasRequiredPlayers)
            Text(
                "Waiting for more players... (${roomData.players.length}/${roomData.game.playerLimit})"),
          if (roomData.hasRequiredPlayers)
            Column(
              children: [
                const Text("Player requirement has been met."),
                if (gameManager.player == roomData.host)
                  TextButton(
                      onPressed: () {
                        gameManager.startGame();
                      },
                      child: const Text("Start")),
                if (gameManager.player != roomData.host)
                  const Text("Waiting for host to start..."),
              ],
            )
        ],
      ),
    );
  }

  Widget _gameWidget(BuildContext context, RoomData roomData) {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            "It is ${roomData.gameState!["currentPlayer"] < roomData.players.length ? roomData.players[roomData.gameState!["currentPlayer"]].name : "No one"}'s turn"),
        _tableWidget(context, roomData),
      ],
    ));
  }

  Widget _tableWidget(BuildContext context, RoomData roomData) {
    List<IconData> icons = [Icons.close, Icons.circle_outlined];
    List<Row> rows = [];
    for (int i = 0; i < 9; i += 3) {
      rows.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: joinWidgets(
              List<int>.from(roomData.gameState!["board"])
                  .sublist(i, i + 3)
                  .mapIndexed((j, e) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: TextButton(
                              onPressed: () async {
                                await gameManager
                                    .sendGameEvent({"position": i + j});
                              },
                              child: e == -1
                                  ? const Text("")
                                  : Icon(icons[e], size: 48)),
                        ),
                      ))
                  .toList(),
              const SizedBox(
                  height: 100,
                  child: VerticalDivider(thickness: 2, width: 4)))));
    }
    return Column(
        children: joinWidgets(
            rows,
            const SizedBox(
                width: (100 + 4 * 2) * 3 + 4 * 2,
                child: Divider(thickness: 2, height: 4))));
  }
}

List<Widget> joinWidgets(List<Widget> widgets, Widget separator) {
  List<Widget> result = [];
  for (Widget widget in widgets) {
    result.add(widget);
    if (widgets.last != widget) {
      result.add(separator);
    }
  }
  return result;
}
