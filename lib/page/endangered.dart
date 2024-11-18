import "package:flutter/material.dart";
import "package:flutter_fire_engine/example/endangered.dart";
import "package:flutter_fire_engine/logic/utils.dart";
import "package:flutter_fire_engine/model/game_builder.dart";
import "package:flutter_fire_engine/model/game_manager.dart";
import "package:flutter_fire_engine/model/player.dart";
import "package:collection/collection.dart";
import "package:flutter_fire_engine/page/lobby_widget.dart";
import "package:pair/pair.dart";

class EndangeredPage extends StatefulWidget {
  const EndangeredPage({super.key});

  @override
  State<EndangeredPage> createState() => _EndangeredPageState();
}

class _EndangeredPageState extends State<EndangeredPage> {
  late GameManager gameManager;

  void _sendSnackBar(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    gameManager = GameManager.instance;
    gameManager.setOnGameEvent<EndangeredGameState>((event, gameState) {
      if (event["type"] == "answerQuestion" && gameState.state == "selecting") {
        final question =
            gameManager.getGameResponse({"type": "getCurrentQuestion"}).right
                as Map<String, dynamic>;
        final correctIndex = gameManager
            .getGameResponse({"type": "getCurrentCorrectIndex"}).right as int;
        if (event["index"] == correctIndex) {
          if (gameManager.player != event.author) {
            _sendSnackBar(
                "Question was answered correctly. Correct answer was \"${question["answers"][correctIndex]}\"");
          } else {
            _sendSnackBar("Question was answered correctly");
          }
        } else {
          _sendSnackBar(
              "Correct answer was \"${question["answers"][correctIndex]}\"");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameBuilder<EndangeredGameState>(
      builder: (context, roomData, gameManager) =>
          LobbyWidget(roomData: roomData, gameManager: gameManager),
      gameStartedBuilder: (context, roomData, gameState, gameManager) {
        switch (roomData.gameState!.state) {
          case "selecting":
            return _selectingStateWidget(roomData.gameState!);
          case "buzzing":
            return _buzzingStateWidget();
          case "answering":
            return _answeringStateWidget(roomData.gameState!);
        }
        return Container();
      },
    );
  }

  Widget _scoresWidget(Map<Player, int> scores) {
    return Text(
        "Scores — ${scores.entries.map((entry) => "${entry.key.name}: ${entry.value}").join(", ")}");
  }

  Widget _selectingStateWidget(EndangeredGameState gameState) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _scoresWidget(gameState.scores),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                "It is ${gameState.currentSelector.name}'s turn to select"),
          ),
          _questionsTable(gameState),
        ],
      ),
    );
  }

  Widget _questionsTable(EndangeredGameState gameState) {
    final questions =
        gameManager.getGameResponse({"type": "getQuestions"}).right
            as Map<String, Map<String, Map<String, dynamic>>>;
    final difficulties = gameManager
        .getGameResponse({"type": "getDifficulties"}).right as List<String>;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: joinWidgets(
            questions.entries
                .map((q) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[Text(q.key), const Divider()] +
                          difficulties.map((d) {
                            final answeredQuestions =
                                gameState.answeredQuestions;
                            return TextButton(
                                onPressed: () {
                                  gameManager.sendGameEvent({
                                    "type": "selectQuestion",
                                    "category": q.key,
                                    "difficulty": d
                                  });
                                },
                                child: Text(
                                  d,
                                  style: TextStyle(
                                      decoration: answeredQuestions
                                              .contains(Pair(q.key, d))
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none),
                                ));
                          }).toList(),
                    ))
                .toList(),
            const SizedBox(height: 200, child: VerticalDivider())),
      ),
    );
  }

  Widget _buzzingStateWidget() {
    final currentQuestion =
        gameManager.getGameResponse({"type": "getCurrentQuestion"}).right
            as Map<String, dynamic>;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 300, child: Text(currentQuestion["question"])),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 150,
              height: 150,
              child: ElevatedButton(
                onPressed: () {
                  gameManager.sendGameEvent({"type": "buzzIn", "status": true});
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "BUZZER",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _answeringStateWidget(EndangeredGameState gameState) {
    final currentQuestion =
        gameManager.getGameResponse({"type": "getCurrentQuestion"}).right
            as Map<String, dynamic>;
    final buzzedIn = gameState.buzzedIn!;
    final currentAnswerer = buzzedIn[gameState.currentAnswerer!];
    final currentAnswers = gameState.currentAnswers!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("It is ${currentAnswerer.name}'s turn to answer"),
              ),
            ] +
            (currentQuestion["answers"] as List<String>)
                .mapIndexed((i, a) => TextButton(
                    onPressed: () {
                      gameManager.sendGameEvent(
                          {"type": "answerQuestion", "index": i});
                    },
                    child: Text(
                      a,
                      style: TextStyle(
                        decoration: currentAnswers.contains(i)
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    )))
                .toList(),
      ),
    );
  }
}
