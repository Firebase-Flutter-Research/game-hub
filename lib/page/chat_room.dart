import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';
import 'package:flutter_fire_engine/model/player.dart';

class Message {
  final String message;
  final Player author;

  const Message({required this.message, required this.author});
}

class ChatMessages extends StatefulWidget {
  final List<Message> messages;

  const ChatMessages({super.key, required this.messages});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  void sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await GameManager.instance.sendOtherEvent({"message": text});
    _textController.clear();
  }

  void scrollToBottom() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Messages"),
      content: SizedBox(
        width: 300,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.messages
                      .expand((message) => [
                            Text(
                                "${message.author.name} -> ${message.message}"),
                            const Divider(),
                          ])
                      .toList(),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                TextButton(onPressed: sendMessage, child: const Text("Send"))
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ChatRoomButton extends StatefulWidget {
  const ChatRoomButton({super.key});

  @override
  State<ChatRoomButton> createState() => _ChatRoomButtonState();
}

class _ChatRoomButtonState extends State<ChatRoomButton> {
  final messages = <Message>[];
  final chatMessagesKey = GlobalKey<_ChatMessagesState>();
  int pendingMessages = 0;

  @override
  void initState() {
    super.initState();

    GameManager.instance.setOnOtherEvent((event) {
      setState(() {
        messages.add(
            Message(message: event.payload!["message"], author: event.author));
        pendingMessages += 1;
      });
      chatMessagesKey.currentState?.setState(() {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => chatMessagesKey.currentState?.scrollToBottom());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: pendingMessages > 0,
      label: Text("$pendingMessages"),
      child: FloatingActionButton(
          child: const Icon(Icons.chat),
          onPressed: () async {
            setState(() {
              pendingMessages = 0;
            });
            await showDialog(
                context: context,
                builder: (context) {
                  return ChatMessages(key: chatMessagesKey, messages: messages);
                });
            setState(() {
              pendingMessages = 0;
            });
          }),
    );
  }
}
