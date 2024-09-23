import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/connect_four.dart';
import 'package:flutter_fire_engine/example/checkers.dart';
import 'package:flutter_fire_engine/example/dice_roller.dart';
import 'package:flutter_fire_engine/example/rock_paper_scissors.dart';
import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:flutter_fire_engine/page/chat_room.dart';
import 'package:flutter_fire_engine/page/connect_four.dart';
import 'package:flutter_fire_engine/page/checkers.dart';
import 'package:flutter_fire_engine/page/dice_roller.dart';
import 'package:flutter_fire_engine/page/rock_paper_scissors.dart';
import 'package:flutter_fire_engine/page/tic_tac_toe.dart';

class InGamePage extends StatefulWidget {
  const InGamePage({super.key});

  @override
  State<InGamePage> createState() => _InGamePageState();
}

class _InGamePageState extends State<InGamePage> {
  late GameManager gameManager;

  // Add more games to game hub via this function.
  Widget getGameWidget(RoomData roomData) {
    switch (roomData.game.runtimeType) {
      case TicTacToe:
        return TicTacToePage(roomData: roomData);
      case ConnectFour:
        return ConnectFourPage(roomData: roomData);
      case Checkers:
        return CheckersPage(roomData: roomData);
      case RockPaperScissors:
        return RockPaperScissorsPage(roomData: roomData);
      case DiceRoller:
        return DiceRollerPage(roomData: roomData);
      default:
        return Container();
    }
  }

  @override
  void initState() {
    super.initState();
    gameManager = GameManager.instance;
    gameManager.setOnLeave(() {
      if (!context.mounted) return;
      Navigator.of(context).popUntil(ModalRoute.withName('/rooms'));
    });
    gameManager.setOnGameStop((log) async {
      if (!context.mounted) return;
      if (log == null) return;
      showDialog(
          context: context,
          useRootNavigator: true,
          builder: (context) => AlertDialog(
              title: Text(
                  log["draw"] ? "It's a draw!" : "${log['winnerName']} won!")));
    });
    gameManager.setOnGameEventFailure((failure) {
      if (!context.mounted) return;
      if (failure.message != null) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message!)));
      }
    });
    gameManager.setOnPlayerJoin((player) {
      if (!context.mounted) return;
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
    gameManager.setOnHostReassigned((newHost, oldHost) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(
                "${oldHost.name} has left the game. ${newHost.name} is now the host.")));
    });
    gameManager.setOnGameStartFailure((failure) {
      if (!context.mounted) return;
      if (failure.message != null) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message!)));
      }
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
              return getGameWidget(roomData);
            }),
        floatingActionButton: ChatRoomButton(),
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
}
