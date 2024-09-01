import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';

class GameManager {
  static const _collectionPrefix = "Rooms";
  static const _playersCollectionName = "Players";
  static const _eventsCollectionName = "Events";
  static const _timestampName = "timestamp";
  static final _gameManager =
      GameManager(player: Player(id: Random().nextInt(0x80000000)));

  final Player player;
  var _roomDataStreamController = StreamController<RoomData>();

  Game? _game;
  Room? _room;
  DocumentReference<Map<String, dynamic>>? _reference;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _playersStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _eventsStream;
  int? _lastProcessedTimestamp;
  void Function(Map<String, dynamic>)? _onGameEnd;

  GameManager({required this.player});

  static GameManager get instance => _gameManager;

  String get collectionName => "$_collectionPrefix:${_game?.name}";

  Stream<RoomData> get roomDataStream => _roomDataStreamController.stream;
  DocumentReference<Map<String, dynamic>>? get reference => _reference;

  void setGame(Game game) {
    _game = game;
  }

  bool hasGame() {
    return _game != null;
  }

  void setPlayerName(String name) {
    player.name = name;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getRooms() {
    if (_game == null) throw Exception("Game has not been set");
    return FirebaseFirestore.instance.collection(collectionName).snapshots();
  }

  void callPlayerEvents(List<Player> updatedPlayers) {
    final oldPlayersSet = _room!.players.toSet();
    final updatedPlayersSet = updatedPlayers.toSet();
    final deletedPlayers = oldPlayersSet.difference(updatedPlayersSet);
    final newPlayers = updatedPlayersSet.difference(oldPlayersSet);
    for (final player in deletedPlayers) {
      _game!.onPlayerLeave(
          player: player, gameState: _room!.gameState, players: updatedPlayers);
    }
    for (final player in newPlayers) {
      _game!.onPlayerJoin(
          player: player, gameState: _room!.gameState, players: updatedPlayers);
    }
  }

  void updateRoomData() {
    if (_room == null) throw Exception("Room not assigned");
    _roomDataStreamController.add(_room!.getRoomData());
  }

  void setupStreams() {
    if (_reference == null || _room == null) {
      throw Exception("Room reference not set");
    }
    _playersStream = _reference!.collection(_playersCollectionName).snapshots();
    _eventsStream = _reference!.collection(_eventsCollectionName).snapshots();
    _playersStream!.listen((playersSnapshot) {
      if (_reference == null) return;
      final players =
          playersSnapshot.docs.map((p) => Player.fromJson(p.data())).toList();
      callPlayerEvents(players);
      _room!.players = players;
      updateRoomData();
    });
    _eventsStream!.listen((eventsSnapshot) {
      if (_reference == null) return;
      final events = eventsSnapshot.docs
          .map((e) => e.data())
          .where((e) => e[_timestampName] > (_lastProcessedTimestamp ?? 0))
          .toList();
      for (final event in events) {
        _room!.processEvent(event);
      }
      _lastProcessedTimestamp = DateTime.timestamp().millisecondsSinceEpoch;
      _room!.events = events;
      updateRoomData();
      final log = _room!.checkGameEnd();
      if (log != null) {
        // TODO: Add any other game end logic.
        if (_onGameEnd != null) _onGameEnd!(log);
      }
    });
  }

  Future<bool> createRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_reference != null) return false;
    _room = Room.createRoom(game: _game!, player: player);
    _reference =
        await FirebaseFirestore.instance.collection(collectionName).add({});
    setupStreams();
    await _reference!.collection(_playersCollectionName).add(player.toJson());
    updateRoomData();
    return true;
  }

  Future<bool> joinRoom(
      DocumentReference<Map<String, dynamic>> reference) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_reference != null) return false;
    final players = (await reference.collection(_playersCollectionName).get())
        .docs
        .map((e) => Player.fromJson(e.data()))
        .toList();
    if (players.contains(player)) return false;
    _room = Room.joinRoom(
        player: player,
        game: _game!,
        players: players,
        events: (await reference.collection(_eventsCollectionName).get())
            .docs
            .map((e) => e.data())
            .toList());
    _reference = reference;
    setupStreams();
    await _reference!.collection(_playersCollectionName).add(player.toJson());
    updateRoomData();
    return true;
  }

  Future<bool> leaveRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _reference == null) return false;
    final left = _room!.leaveRoom(player);
    if (!left) return false;
    final playerReference = (await _reference
            ?.collection(_playersCollectionName)
            .where('id', isEqualTo: player.id)
            .get())
        ?.docs
        .firstOrNull
        ?.reference;
    await playerReference?.delete();
    if (_room!.players.isEmpty) await deleteRoom(_reference!);
    _reference = null;
    _room = null;
    _createAndDisposeStream();
    return true;
  }

  Future<void> deleteRoom(
      DocumentReference<Map<String, dynamic>> reference) async {
    await reference.delete();
  }

  Future<CheckResult> performEvent(Map<String, dynamic> event) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _reference == null) throw Exception("Room not set.");
    final checkResult = _room!.checkPerformEvent(event: event, player: player);
    if (checkResult is CheckResultFailure) {
      if (kDebugMode) {
        print(checkResult.message);
      }
      return checkResult;
    }
    await _reference!.collection(_eventsCollectionName).add(event
      ..addAll({_timestampName: DateTime.timestamp().millisecondsSinceEpoch}));
    return checkResult;
  }

  void setOnGameEnd(void Function(Map<String, dynamic>) callback) {
    _onGameEnd = callback;
  }

  void _createAndDisposeStream() {
    _roomDataStreamController.close();
    _roomDataStreamController = StreamController();
  }
}
