import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fire_engine/model/player.dart';

enum EventType {
  gameEvent(key: "gameEvent"),
  playerJoinRequest(key: "playerJoinRequest"),
  playerJoinDenied(key: "playerJoinedDenied"),
  playerJoin(key: "playerJoin"),
  playerLeave(key: "playerLeave"),
  gameStart(key: "gameStart"),
  gameStop(key: "gameStop");

  final String key;

  const EventType({required this.key});

  static EventType fromKey(String key) =>
      EventType.values.where((e) => e.key == key).first;
}

class Event {
  final EventType type;
  final Timestamp timestamp;
  final Player author;
  final Map<String, dynamic>? payload;

  const Event(
      {required this.type,
      required this.timestamp,
      required this.author,
      required this.payload});

  Map<String, dynamic> toJson() => {
        "type": type.key,
        "timestamp": timestamp,
        "author": author.toJson(),
        "payload": payload,
      };

  static Event fromJson(Map<String, dynamic> json) => Event(
        type: EventType.fromKey(json["type"]),
        timestamp: json["timestamp"],
        author: Player.fromJson(json["author"]),
        payload: json["payload"],
      );
}
