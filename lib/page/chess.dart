import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/chess.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/room.dart';
import 'package:pair/pair.dart';

class ChessPage extends StatefulWidget {
  const ChessPage({super.key});

  @override
  State<ChessPage> createState() => _ChessPageState();
}

class _ChessPageState extends State<ChessPage> {
  late GameManager gameManager;
  List<String>? possibleMoves;
  String? selectedPiece;

  @override
  void initState() {
    super.initState();
    gameManager = GameManager.instance;
    gameManager.setOnGameEnd((log) async {
      Navigator.of(context).pop();
      gameManager.leaveRoom();
      showDialog(
          context: context,
          useRootNavigator: false,
          builder: (context) => AlertDialog(
              title: Text(
                  log["draw"] ? "It's a draw!" : "${log['winnerName']} won!")));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (popped) async {
        if (popped) return;
        await gameManager.leaveRoom();
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chess"),
        ),
        body: StreamBuilder(
            stream: gameManager.roomDataStream,
            builder: (context, snapshot) {
              if (snapshot.data == null || !context.mounted) return Container();
              final roomData = snapshot.data!;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!(roomData.gameState["hasRequiredPlayers"] ?? false))
                      const Text("Waiting for more players..."),
                    if (roomData.gameState["hasRequiredPlayers"] ?? false)
                      Column(
                        children: [
                          Text(
                              "It is ${roomData.gameState["currentPlayer"] < roomData.players.length ? roomData.players[roomData.gameState["currentPlayer"]].name : "No one"}'s turn"),
                          _chessboardWidget(context, roomData),
                        ],
                      ),
                  ],
                ),
              );
            }),
      ),
    );
  }

  Widget _chessboardWidget(BuildContext context, RoomData roomData) {
    final board = roomData.gameState["board"];

    return Column(
      children: board.mapIndexed((i, row) => Row(
            children: row
                .mapIndexed((j, piece) => _chessTileWidget(i, j, piece, board)),
          )),
    );
  }

  Widget _chessTileWidget(
      int i, int j, Piece? piece, List<List<Piece?>> board) {
    final icons = <PieceColor, Map<PieceType, String>>{
      PieceColor.white: {
        PieceType.pawn: "♙",
        PieceType.rook: "♖ ",
        PieceType.bishop: "♗",
        PieceType.knight: "♘",
        PieceType.queen: "♕",
        PieceType.king: "♔"
      },
      PieceColor.black: {
        PieceType.pawn: "♟",
        PieceType.rook: "♜ ",
        PieceType.bishop: "♝",
        PieceType.knight: "♞",
        PieceType.queen: "♛",
        PieceType.king: "♚"
      }
    };
    return GestureDetector(
      onTap: () {
        if (possibleMoves == null) {
          // TODO: PieceColor.white is a placeholder. Make it the current player's color
          if (piece != null && piece.color == PieceColor.white) {
            selectedPiece = Chess.fromMatrixPosition(Pair(i, j));
            possibleMoves = piece.type.possibleTargets(board, selectedPiece!);
          } // else: do nothing
        } else {
          if (possibleMoves!.contains(Chess.fromMatrixPosition(Pair(i, j)))) {
            gameManager.performEvent({
              "position": selectedPiece,
              "target": Chess.fromMatrixPosition(Pair(i, j))
            }); // TODO: is this event correct?
          } else {
            possibleMoves = null;
            selectedPiece = null;
          }
        }
      },
      child: Container(
        // TODO: chessboard pattern + highlighted possibleMoves logic goes in color
        color: Colors.white,
        child: piece == null
            ? const Text("")
            : Text("${icons[piece.color]![piece.type]}"),
      ),
    );
  }
}
