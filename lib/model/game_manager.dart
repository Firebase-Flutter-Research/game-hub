import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:flutter_fire_engine/model/room.dart';

class GameManager {
  static const _collectionPrefix = "Rooms";
  static const _eventsCollectionName = "Events";
  static const _eventLimit = 100;

  static final _gameManager =
      GameManager(player: Player(id: Random().nextInt(0x80000000)));

  final Player player;
  var _roomDataStreamController = StreamController<RoomData>();

  Game? _game;
  Room? _room;
  DocumentReference<Map<String, dynamic>>? _roomReference;
  DocumentReference<Map<String, dynamic>>? _concatenatedEventReference;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _eventStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _roomStream;
  Timestamp? _lastProcessedTimestamp;
  bool _readingLiveEvents = false;

  void Function(Player)? _onPlayerJoin;
  void Function()? _onJoin;
  void Function(Player)? _onPlayerLeave;
  void Function()? _onLeave;
  void Function(Event)? _onEventProcessed;
  void Function(CheckResultFailure)? _onEventFailure;
  void Function()? _onGameStart;
  void Function(Map<String, dynamic>?)? _onGameStop;
  void Function()? _onRoomDeletedCallback;

  GameManager({required this.player});

  static GameManager get instance => _gameManager;

  String get _collectionName => "$_collectionPrefix:${_game?.name}";

  Stream<RoomData> get roomDataStream => _roomDataStreamController.stream;
  Game? get game => _game;

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
    return FirebaseFirestore.instance.collection(_collectionName).snapshots();
  }

  List<Event> _fromConcatenatedEvents(
      List<Map<String, dynamic>> concatenatedEvents) {
    return concatenatedEvents
        .expand((concatEvent) =>
            List<Map<String, dynamic>>.from(concatEvent["events"])
                .map((event) => Event.fromJson(event)))
        .toList();
  }

  void _updateRoomData() {
    if (_room == null) throw Exception("Room not assigned");
    _roomDataStreamController.add(_room!.getRoomData());
  }

  void _setupStreams() {
    if (_roomReference == null || _room == null) {
      throw Exception("Room reference not set");
    }

    _createAndDisposeStream();

    _roomStream = _roomReference!.snapshots();
    _roomStream!.listen((roomSnapshot) async {
      if (!roomSnapshot.exists) await _onRoomDeleted();
    });

    _eventStream =
        _roomReference!.collection(_eventsCollectionName).snapshots();
    _eventStream!.listen((eventSnapshots) async {
      if (_roomReference == null) return;

      _concatenatedEventReference =
          _findCurrentConcatenation(eventSnapshots.docs);
      final events = _fromConcatenatedEvents(
          eventSnapshots.docs.map((e) => e.data()).toList())
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final filteredEvents = events.where((e) =>
          e.timestamp.compareTo(_lastProcessedTimestamp ??
              Timestamp.fromMillisecondsSinceEpoch(0)) >
          0);

      for (final event in filteredEvents) {
        _processEvent(event);
      }
      _lastProcessedTimestamp = events.lastOrNull?.timestamp;

      _room!.events = events;
      _updateRoomData();

      final log = _room!.checkGameEnd();
      if (log != null) {
        await stopGame(log);
      }

      _readingLiveEvents = true;
    });
  }

  Future<bool> _sendRoomJoinEvent(
      DocumentSnapshot<Map<String, dynamic>> room) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (room.data() == null ||
        room.data()!["playerCount"] >= _game!.playerLimit) {
      return false;
    }
    await _sendEvent(EventType.playerJoin);
    await room.reference.update({"playerCount": FieldValue.increment(1)});
    return true;
  }

  Future<bool> createRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_roomReference != null) return false;
    _room = Room.createRoom(game: _game!, host: player);
    _roomReference = await FirebaseFirestore.instance
        .collection(_collectionName)
        .add({"host": player.toJson(), "playerCount": 0, "gameStarted": false});
    _concatenatedEventReference = await _createConcatenatedEvent();
    _setupStreams();
    _updateRoomData();
    return await _sendRoomJoinEvent(await _roomReference!.get());
  }

  Future<bool> joinRoom(DocumentSnapshot<Map<String, dynamic>> room) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_roomReference != null) return false;
    if (room["gameStarted"]) return false;
    final eventDocs =
        (await room.reference.collection(_eventsCollectionName).get()).docs;
    _concatenatedEventReference = _findCurrentConcatenation(eventDocs);
    final success = await _sendRoomJoinEvent(room);
    if (!success) return false;
    if (_roomReference != null) return false; // Check again for async gap
    _room = Room.createRoom(game: _game!, host: Player.fromJson(room["host"]));
    _roomReference = room.reference;
    _setupStreams();
    _updateRoomData();
    if (_onJoin != null && _readingLiveEvents) _onJoin!();
    _readingLiveEvents = false;
    return true;
  }

  Future<DocumentReference<Map<String, dynamic>>>
      _createConcatenatedEvent() async {
    return _roomReference!
        .collection(_eventsCollectionName)
        .add({"events": []});
  }

  DocumentReference<Map<String, dynamic>>? _findCurrentConcatenation(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    for (var doc in docs) {
      if (doc.data()["events"].length < _eventLimit) {
        return doc.reference;
      }
    }
    return null;
  }

  Future<void> leaveRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _roomReference == null) {
      return;
    }

    final roomReference = _roomReference!;
    _roomReference = null;

    _room!.leaveRoom(player);
    if (_room!.host == player) await deleteRoom(roomReference);

    if ((await roomReference.get()).exists) {
      await _sendEvent(EventType.playerLeave);
      await roomReference.update({"playerCount": FieldValue.increment(-1)});
    }

    _eventStream = null;
    _room = null;
    _lastProcessedTimestamp = null;

    if (_onLeave != null && _readingLiveEvents) _onLeave!();
  }

  Future<void> deleteRoom(
      DocumentReference<Map<String, dynamic>> reference) async {
    final events = await reference.collection(_eventsCollectionName).get();
    for (var event in events.docs) {
      await event.reference.delete();
    }
    await reference.delete();
  }

  Future<void> _onRoomDeleted() async {
    await leaveRoom();
    if (_onRoomDeletedCallback != null && _readingLiveEvents) {
      _onRoomDeletedCallback!();
    }
  }

  Future<CheckResult> sendGameEvent(Map<String, dynamic> event) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _roomReference == null) {
      throw Exception("Room not set.");
    }
    final checkResult = _room!.checkPerformEvent(event: event, player: player);
    if (checkResult is CheckResultFailure) {
      if (_onEventFailure != null && _readingLiveEvents) {
        _onEventFailure!(checkResult);
      }
      return checkResult;
    }
    await _sendEvent(EventType.gameEvent, event);
    return checkResult;
  }

  Future<void> startGame() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _roomReference == null) return;
    if (player != _room!.host) return;
    await _sendEvent(EventType.gameStart);
    await _roomReference!.update({"gameStarted": true});
  }

  Future<void> stopGame([Map<String, dynamic>? log]) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _roomReference == null) return;
    if (player != _room!.host) return;
    await _sendEvent(EventType.gameStop, log);
    await _roomReference!.update({"gameStarted": false});
  }

  Future<void> _sendEvent(EventType type,
      [Map<String, dynamic>? payload]) async {
    _concatenatedEventReference ??= await _createConcatenatedEvent();
    _concatenatedEventReference!.update({
      "events": FieldValue.arrayUnion([
        Event(
                type: type,
                timestamp: Timestamp.now(),
                author: player,
                payload: payload)
            .toJson()
      ])
    });
  }

  void _processEvent(Event event) {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null) return;
    switch (event.type) {
      case EventType.gameEvent:
        return _processGameEvent(event);
      case EventType.playerJoin:
        return _processPlayerJoinEvent(event.author);
      case EventType.playerLeave:
        return _processPlayerLeaveEvent(event.author);
      case EventType.gameStart:
        return _processGameStartEvent();
      case EventType.gameStop:
        return _processGameStopEvent(event.payload);
    }
  }

  void _processGameEvent(Event event) async {
    _room!.processEvent(event);
    if (_onEventProcessed != null && _readingLiveEvents) {
      _onEventProcessed!(event);
    }
  }

  void _processPlayerJoinEvent(Player player) async {
    _room!.joinRoom(player);
    if (_onPlayerJoin != null && this.player != player && _readingLiveEvents) {
      _onPlayerJoin!(player);
    }
  }

  void _processPlayerLeaveEvent(Player player) async {
    _room!.leaveRoom(player);
    if (_onPlayerLeave != null && this.player != player && _readingLiveEvents) {
      _onPlayerLeave!(player);
    }
    if (_room!.players.isEmpty) {
      await deleteRoom(_roomReference!);
    }
    if (!_room!.hasRequiredPlayers) {
      await stopGame();
    }
  }

  void _processGameStartEvent() async {
    _room!.startGame();
    if (_onGameStart != null && _readingLiveEvents) _onGameStart!();
  }

  void _processGameStopEvent(Map<String, dynamic>? log) async {
    _room!.stopGame();
    if (_onGameStop != null && _readingLiveEvents) _onGameStop!(log);
  }

  void setOnPlayerJoin(void Function(Player) callback) {
    _onPlayerJoin = callback;
  }

  void setOnJoin(void Function() callback) {
    _onJoin = callback;
  }

  void setOnPlayerLeave(void Function(Player) callback) {
    _onPlayerLeave = callback;
  }

  void setOnLeave(void Function() callback) {
    _onLeave = callback;
  }

  void setOnEventProcess(void Function(Event) callback) {
    _onEventProcessed = callback;
  }

  void setOnEventFailure(void Function(CheckResultFailure) callback) {
    _onEventFailure = callback;
  }

  void setOnGameStart(void Function() callback) {
    _onGameStart = callback;
  }

  void setOnGameStop(void Function(Map<String, dynamic>?) callback) {
    _onGameStop = callback;
  }

  void setOnRoomDeleted(void Function() callback) {
    _onRoomDeletedCallback = callback;
  }

  void _createAndDisposeStream() {
    _roomDataStreamController.close();
    _roomDataStreamController = StreamController();
  }
}
