
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      messageContent: "Hello, Will",
      messageType: "receiver",
    ),
    ChatMessage(
      messageContent: "How have you been?",
      messageType: "receiver",
    ),
    ChatMessage(
      messageContent: "Hey Kriss, I am doing fine dude. wbu?",
      messageType: "sender",
    ),
    ChatMessage(
      messageContent: "im doing ok and how is the project going",
      messageType: "receiver",
    ),
    ChatMessage(
      messageContent: "Great",
      messageType: "sender",
    ),
  ];
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
            messageContent: _messageController.text.trim(),
            messageType: "sender"));
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Screen"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              shrinkWrap: true,
              padding: EdgeInsets.only(top: 10, bottom: 10),
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  padding:
                      EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
                  child: Align(
                    alignment: (_messages[index].messageType == "receiver"
                        ? Alignment.topLeft
                        : Alignment.topRight),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: (_messages[index].messageType == "receiver"
                            ? Colors.grey.shade200
                            : Colors.blue[200]),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Text(
                        _messages[index].messageContent,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  String messageContent;
  String messageType;
  ChatMessage({required this.messageContent, required this.messageType});
}
