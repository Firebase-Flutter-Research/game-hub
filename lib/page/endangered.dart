import "package:flutter/material.dart";
import "package:flutter_fire_engine/logic/utils.dart";
import "package:flutter_fire_engine/model/game_manager.dart";
import "package:flutter_fire_engine/model/player.dart";
import "package:flutter_fire_engine/model/room.dart";
import "package:collection/collection.dart";
import "package:pair/pair.dart";

class EndangeredPage extends StatefulWidget {
  final RoomData roomData;

  const EndangeredPage({super.key, required this.roomData});

  @override
  State<EndangeredPage> createState() => _EndangeredPageState();
}

class _EndangeredPageState extends State<EndangeredPage> {
  late GameManager gameManager;

  @override
  void initState() {
    super.initState();
    gameManager = GameManager.instance;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.roomData["state"]) {
      case "selecting":
        return _selectingStateWidget();
      case "buzzing":
        return _buzzingStateWidget();
      case "answering":
        return _answeringStateWidget();
    }
    return Container();
  }

  Widget _selectingStateWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              "It is ${widget.roomData["currentSelector"].name}'s turn to select"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _questionsTable(),
          ),
        ],
      ),
    );
  }

  Widget _questionsTable() {
    final questions =
        gameManager.getGameResponse({"type": "getQuestions"}).right
            as Map<String, Map<String, Map<String, dynamic>>>;
    final difficulties = gameManager
        .getGameResponse({"type": "getDifficulties"}).right as List<String>;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: joinWidgets(
          questions.entries
              .map((q) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                          Row(
                            children: [
                              Text(q.key),
                            ],
                          ),
                          const Divider()
                        ] +
                        difficulties.map((d) {
                          final answeredQuestions =
                              widget.roomData["answeredQuestions"]
                                  as Set<Pair<String, String>>;
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

  Widget _answeringStateWidget() {
    final currentQuestion =
        gameManager.getGameResponse({"type": "getCurrentQuestion"}).right
            as Map<String, dynamic>;
    final buzzedIn = widget.roomData["buzzedIn"] as List<Player>;
    final currentAnswerer = buzzedIn[widget.roomData["currentAnswerer"]];
    final currentAnswers = widget.roomData["currentAnswers"] as Set<int>;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
              Text("It is ${currentAnswerer.name}'s turn to answer"),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                    width: 300, child: Text(currentQuestion["question"])),
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
