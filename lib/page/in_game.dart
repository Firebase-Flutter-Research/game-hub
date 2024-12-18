import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/checkers.dart';
import 'package:flutter_fire_engine/example/connect_four.dart';
import 'package:flutter_fire_engine/example/draw_my_thing.dart';
import 'package:flutter_fire_engine/example/endangered.dart';
import 'package:flutter_fire_engine/example/last_card.dart';
import 'package:flutter_fire_engine/example/memory_match.dart';
import 'package:flutter_fire_engine/example/pong.dart';
import 'package:flutter_fire_engine/example/rock_paper_scissors.dart';
import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:fire_game_infra/fire_game_infra.dart';
import 'package:flutter_fire_engine/page/chat_room.dart';
import 'package:flutter_fire_engine/page/checkers.dart';
import 'package:flutter_fire_engine/page/connect_four.dart';
import 'package:flutter_fire_engine/page/draw_my_thing.dart';
import 'package:flutter_fire_engine/page/endangered.dart';
import 'package:flutter_fire_engine/page/last_card.dart';
import 'package:flutter_fire_engine/page/memory_match.dart';
import 'package:flutter_fire_engine/page/pong.dart';
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
  Widget getGameWidget(Game? game) {
    switch (game.runtimeType) {
      case TicTacToe:
        return TicTacToePage();
      case ConnectFour:
        return ConnectFourPage();
      case Checkers:
        return CheckersPage();
      case RockPaperScissors:
        return RockPaperScissorsPage();
      case LastCard:
        return LastCardPage();
      case MemoryMatch:
        return MemoryMatchPage();
      case DrawMyThing:
        return DrawMyThingWidget();
      case Endangered:
        return EndangeredPage();
      case Pong:
        return PongPage();
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
    gameManager.setOnGameEvent((event, gameState) {});
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
        body: getGameWidget(gameManager.game),
        floatingActionButton: ChatRoomButton(),
      ),
    );
  }
}
