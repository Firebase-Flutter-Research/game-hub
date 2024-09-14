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
  Completer<bool>? _joinRoomResponse;
  Timer? _joinRoomTimeout;

  void Function(Player)? _onPlayerJoin;
  void Function()? _onPlayerJoinDenied;
  void Function(Player)? _onPlayerLeave;
  void Function()? _onLeave;
  void Function(Player, Map<String, dynamic>)? _onGameEvent;
  void Function(CheckResultFailure)? _onEventFailure;
  void Function()? _onGameStart;
  void Function(Map<String, dynamic>?)? _onGameStop;
  void Function()? _onHostLeave;

  GameManager({required this.player});

  // Get global device GameManager instance.
  static GameManager get instance => _gameManager;

  String get _collectionName => "$_collectionPrefix:${_game?.name}";

  // Get stream to read RoomData changes.
  Stream<RoomData> get roomDataStream => _roomDataStreamController.stream;

  // Get currently assigned game.
  Game? get game => _game;

  // Assign game.
  void setGame(Game game) {
    _game = game;
  }

  // Check if a game has been assigned.
  bool hasGame() {
    return _game != null;
  }

  // Set player's name.
  void setPlayerName(String name) {
    player.name = name;
  }

  // Get stream of rooms from Firebase.
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
    _lastProcessedTimestamp = null;

    _roomStream = _roomReference!.snapshots();
    _roomStream!.listen((roomSnapshot) async {
      if (!roomSnapshot.exists) await _onRoomDeleted();
    });

    _eventStream =
        _roomReference!.collection(_eventsCollectionName).snapshots();
    _eventStream!.listen((eventSnapshots) async {
      if (_roomReference == null || _room == null) return;

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

      if (_roomReference == null || _room == null) {
        return; // Check again after processing events
      }

      _room!.events = events;
      _updateRoomData();

      final log = _room!.checkGameEnd();
      if (log != null) {
        await stopGame(log);
      }

      _readingLiveEvents = true;
    });
  }

  // Create a new room and join it.
  Future<bool> createRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_roomReference != null && _room != null) return false;
    _room = Room.createRoom(game: _game!, host: player);
    _roomReference = await FirebaseFirestore.instance
        .collection(_collectionName)
        .add({"host": player.toJson(), "playerCount": 0});
    _concatenatedEventReference = await _createConcatenatedEvent();
    _setupStreams();
    _updateRoomData();
    _readingLiveEvents = true;
    _joinRoomResponse = Completer();
    await _sendEvent(EventType.playerJoin, {"player": player.toJson()});
    await _roomReference!.update({"playerCount": FieldValue.increment(1)});
    return _joinRoomResponse!.future;
  }

  // Join a room from a Firebase document.
  Future<bool> joinRoom(DocumentSnapshot<Map<String, dynamic>> room) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_roomReference != null && _room != null) return false;
    final eventDocs =
        (await room.reference.collection(_eventsCollectionName).get()).docs;
    _concatenatedEventReference = _findCurrentConcatenation(eventDocs);
    _room = Room.createRoom(game: _game!, host: Player.fromJson(room["host"]));
    _roomReference = room.reference;
    _setupStreams();
    _updateRoomData();
    _readingLiveEvents = false;
    _joinRoomResponse = Completer();
    await _sendEvent(EventType.playerJoinRequest);

    // Process as join denied if timeout
    _joinRoomTimeout = Timer(const Duration(seconds: 5), () {
      if (_joinRoomResponse != null &&
          !_joinRoomResponse!.isCompleted &&
          _roomReference != null &&
          _room != null) {
        _processPlayerJoinDeniedEvent(player);
      }
    });

    return _joinRoomResponse!.future;
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

  // Leave current room.
  Future<void> leaveRoom() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _roomReference == null) {
      return;
    }

    final roomReference = _roomReference!;
    _roomReference = null;

    _room!.leaveRoom(player);

    if ((await roomReference.get()).exists) {
      await _sendEvent(EventType.playerLeave);
      await roomReference.update({"playerCount": FieldValue.increment(-1)});
    }

    if (_room!.host == player) await _deleteRoom(roomReference);

    if (_onLeave != null && _readingLiveEvents) _onLeave!();

    _room = null;
    _eventStream = null;
    _lastProcessedTimestamp = null;
    _joinRoomResponse = null;
  }

  Future<void> _deleteRoom(
      DocumentReference<Map<String, dynamic>> reference) async {
    final events = await reference.collection(_eventsCollectionName).get();
    for (var event in events.docs) {
      await event.reference.delete();
    }
    await reference.delete();
  }

  Future<void> _onRoomDeleted() async {
    await leaveRoom();
  }

  // Send event to be processed by the game rules. Takes a payload json as input and returns a result.
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

  // Start a game. Can only be called by the host.
  Future<void> startGame() async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _roomReference == null) return;
    if (player != _room!.host) return;
    if (_room!.gameStarted || !_room!.hasRequiredPlayers) return;
    await _sendEvent(EventType.gameStart);
  }

  // Stop the current game. Can only be called by the host.
  Future<void> stopGame([Map<String, dynamic>? log]) async {
    if (_game == null) throw Exception("Game not found. Ensure game is set.");
    if (_room == null || _roomReference == null) return;
    if (player != _room!.host) return;
    if (!_room!.gameStarted) return;
    await _sendEvent(EventType.gameStop, log);
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
    if (_roomReference == null || _room == null) return;
    switch (event.type) {
      case EventType.gameEvent:
        return _processGameEvent(event);
      case EventType.playerJoinRequest:
        return _processPlayerJoinRequestEvent(event.author);
      case EventType.playerJoinDenied:
        return _processPlayerJoinDeniedEvent(
            Player.fromJson(event.payload!["player"]!));
      case EventType.playerJoin:
        return _processPlayerJoinEvent(
            Player.fromJson(event.payload!["player"]!));
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
    if (_onGameEvent != null && _readingLiveEvents) {
      _onGameEvent!(event.author, event.payload!);
    }
  }

  void _processPlayerJoinRequestEvent(Player player) async {
    if (this.player != _room!.host) return;
    if (_room!.gameStarted || _room!.players.length >= _game!.playerLimit) {
      await _sendEvent(EventType.playerJoinDenied, {"player": player.toJson()});
      return;
    }
    _room!.joinRoom(player);
    await _sendEvent(EventType.playerJoin, {"player": player.toJson()});
    await _roomReference!.update({"playerCount": FieldValue.increment(1)});
  }

  void _processPlayerJoinDeniedEvent(Player player) async {
    if (this.player != player) return;
    if (_room!.players.contains(player)) return;
    if (!_readingLiveEvents) return;
    _roomReference = null;
    _room = null;
    _eventStream = null;
    _lastProcessedTimestamp = null;
    if (_joinRoomResponse != null && !_joinRoomResponse!.isCompleted) {
      _joinRoomResponse!.complete(false);
    }
    if (_onPlayerJoinDenied != null) _onPlayerJoinDenied!();
  }

  void _processPlayerJoinEvent(Player player) async {
    _room!.joinRoom(player);
    if (_onPlayerJoin != null && this.player != player && _readingLiveEvents) {
      _onPlayerJoin!(player);
    }
    if (_readingLiveEvents &&
        this.player == player &&
        _joinRoomResponse != null &&
        !_joinRoomResponse!.isCompleted) {
      _joinRoomResponse!.complete(true);
      if (_joinRoomTimeout != null) _joinRoomTimeout!.cancel();
    }
  }

  void _processPlayerLeaveEvent(Player player) async {
    _room!.leaveRoom(player);
    if (_readingLiveEvents && this.player != player) {
      if (player == _room!.host) {
        if (_onHostLeave != null) _onHostLeave!();
      } else {
        if (_onPlayerLeave != null) _onPlayerLeave!(player);
      }
    }
    if (_room!.gameStarted && !_room!.hasRequiredPlayers) {
      await stopGame();
    }
  }

  void _processGameStartEvent() async {
    if (_room!.startGame()) {
      if (_onGameStart != null && _readingLiveEvents) _onGameStart!();
    }
  }

  void _processGameStopEvent(Map<String, dynamic>? log) async {
    if (_room!.stopGame()) {
      if (_onGameStop != null && _readingLiveEvents) _onGameStop!(log);
    }
  }

  // Pass event function to be called when a player joins.
  void setOnPlayerJoin(void Function(Player) callback) {
    _onPlayerJoin = callback;
  }

  // Pass event function to be called when a player is denied joining.
  void setOnPlayerJoinDenied(void Function() callback) {
    _onPlayerJoinDenied = callback;
  }

  // Pass event function to be called when a player leaves.
  void setOnPlayerLeave(void Function(Player) callback) {
    _onPlayerLeave = callback;
  }

  // Pass event function to be called when you leave.
  void setOnLeave(void Function() callback) {
    _onLeave = callback;
  }

  // Pass event function to be called when a game event has been received.
  void setOnGameEvent(void Function(Player, Map<String, dynamic>) callback) {
    _onGameEvent = callback;
  }

  // Pass event function to be called when an event fails.
  void setOnEventFailure(void Function(CheckResultFailure) callback) {
    _onEventFailure = callback;
  }

  // Pass event function to be called when the game starts.
  void setOnGameStart(void Function() callback) {
    _onGameStart = callback;
  }

  // Pass event function to be called when the game is stopped.
  void setOnGameStop(void Function(Map<String, dynamic>?) callback) {
    _onGameStop = callback;
  }

  // Pass event function to be called when the room is deleted.
  void setOnHostLeave(void Function() callback) {
    _onHostLeave = callback;
  }

  void _createAndDisposeStream() {
    _roomDataStreamController.close();
    _roomDataStreamController = StreamController();
  }
}
