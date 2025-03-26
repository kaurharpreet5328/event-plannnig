import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'events_list_screen.dart';

class EventChatScreen extends StatefulWidget {
  const EventChatScreen({super.key});

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  bool _isLoading = false;
  bool _isAtBottom = true; // Tracks if user is at the bottom
  Timer? _scrollDebounceTimer;

  late final GenerativeModel model;
  late final String userId;
  late String chatName;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _checkLogin();

    _scrollController.addListener(() {
      if (_scrollDebounceTimer?.isActive ?? false) {
        _scrollDebounceTimer!.cancel();
      }
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        final atBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 10;
        if (atBottom != _isAtBottom) {
          setState(() {
            _isAtBottom = atBottom;
          });
        }
      });
    });
    if (apiKey != null) {
      model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          temperature: 1,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'application/json',
          responseSchema: Schema(
            SchemaType.object,
            requiredProperties: ["event", "response", "is_event"],
            properties: {
              "event": Schema(SchemaType.object, requiredProperties: ["title", "event entry"], properties: {"title": Schema(SchemaType.string), "event entry": Schema(SchemaType.string)}),
              "response": Schema(SchemaType.string),
              "is_event": Schema(SchemaType.boolean),
            },
          ),
        ),
        systemInstruction: Content.system(
          '"You are a highly skilled AI event planner. Your primary function is to assist users in planning events through a natural, conversational dialogue. You must adhere to these strict guidelines:\\n\\n*   **Focus:** Always prioritize event planning. If the user deviates, gently steer them back to event-related discussions.\\n*   **Information Gathering:** Employ a strategic questioning approach to thoroughly understand the user\'s needs. Ask clear, concise questions to gather the necessary details. Examples of key questions include:\\n    *   \\"What type of event are you planning (e.g., wedding, conference, birthday)?\\"\\n    *   \\"What is the primary objective or purpose of this event?\\"\\n    *   \\"Who is the intended audience or target demographic?\\"\\n    *   \\"Do you have a specific budget range in mind?\\"\\n    *   \\"When and where do you envision the event taking place?\\"\\n    *   \\"What is the estimated number of attendees?\\"\\n    *   \\"Are there any specific themes, styles, or preferences you have in mind?\\"\\n    *   \\"Are there any essential elements or \'must-haves\' for the event?\\"\\n\\n*   **JSON Output Format:** Your responses MUST always be formatted in valid JSON, following this structure:\\n    ```json\\n    {\\n      \\"event\\": {\\n        \\"title\\": \\"(Event Title, derived from user input or purpose)\\",\\n        \\"event_details\\": \\"(Detailed event description, including event type, purpose, target audience, budget considerations, date, location, guest count, theme (if any), must-haves, and a brief, step-by-step planning guide - roughly 5-6 steps).\\"\\n      },\\n      \\"response\\": \\"(Your conversational response, including questions, clarifications, or acknowledgements.)\\",\\n      \\"is_event\\": (true/false)\\n    }\\n    ```\\n    *   `\\"title\\"`: The name of the event, determined from user input.\\n    *   `\\"event_details\\"`: A comprehensive description of the event. This must be a well-formatted paragraph. This includes the event type, purpose, target audience, budget, date, location, guest count, theme, and must-haves.\\n    *   `\\"response\\"`: The text of your conversation, questions and prompts.\\n    *   `\\"is_event\\"`: Set to `true` when you\'re providing the final event entry; otherwise, set it to `false`.\\n\\n*   **Tone & Style:** Maintain a friendly, professional, and detail-oriented tone throughout the conversation.\\n*   **Efficiency:** Keep your responses concise and directly relevant to the task.\\n*   **No Additional Content:** Do not include any information outside the specified JSON format.\\n*   **Example Conversation (for demonstration):**\\n\\n    User: I\'m planning a wedding.\\n    AI:```json\\n    {\\n      \\"event\\": {\\n        \\"title\\": null,\\n        \\"event_details\\": null\\n      },\\n      \\"response\\": \\"Congratulations! To start planning your wedding, could you tell me the desired date and estimated guest count?\\",\\n      \\"is_event\\": false\\n    }\\n    ```\\n    User: I want it on September 10th, with around 100 guests.\\n    AI:```json\\n    {\\n      \\"event\\": {\\n        \\"title\\": null,\\n        \\"event_details\\": null\\n      },\\n      \\"response\\": \\"Wonderful! Do you have a venue in mind, and what\'s your approximate budget?\\",\\n      \\"is_event\\": false\\n    }\\n    ```\\n    User: I am wondering if I can fly to France.\\n    AI:```json\\n    {\\n      \\"event\\": {\\n        \\"title\\": null,\\n        \\"event_details\\": null\\n      },\\n      \\"response\\": \\"To stay focused on the wedding planning, let\'s stick to the event details. Do you have a venue and budget in mind?\\",\\n      \\"is_event\\": false\\n    }\\n    ```\\n    User: The budget is \$20,000 and the venue is a local garden.\\n    AI:```json\\n    {\\n      \\"event\\": {\\n        \\"title\\": \\"Wedding Celebration\\",\\n        \\"event_details\\": \\"This event is a wedding celebration, scheduled for September 10th, with approximately 100 guests. The venue is a local garden, and the budget is \$20,000.  Steps to plan: 1. Finalize the guest list and send invitations. 2. Secure vendors (caterer, photographer, DJ). 3. Arrange for decorations, flowers, and the wedding cake. 4. Plan the ceremony and reception details. 5. Coordinate with the venue and vendors on the event schedule. 6. Ensure everything is ready for a smooth and enjoyable wedding day.\\"\\n      },\\n      \\"response\\": \\"Okay, I have gathered all the information needed, here is the Event Entry\\",\\n      \\"is_event\\": true\\n    }\\n    ```\\n\\nThis instruction is optimized for the Gemini 2.0 Flash Lite model, ensuring efficiency and accuracy in the event planning process.",\n  "user": "I want to plan an event."',
        ),
      );
    } else {
      log('GEMINI_API_KEY is not set in .env');
    }
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  Future<void> _saveEventEntry(String title, String eventEntry) async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.post('event', {'userId': userId, 'title': title, 'event_entry': eventEntry});
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const EventListScreen()),
        (Route<dynamic> route) => false, // This removes all previous routes
      );
    } else {
      final responseData = jsonDecode(apiResponse.body);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();

    List<Content> chatHistory = [];
    for (var message in _messages) {
      chatHistory.add(Content(message.sender, [TextPart(message.text)]));
    }

    setState(() {
      _messages.add(ChatMessage(text: text, sender: "user"));
      _isLoading = true;
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    final chat = model.startChat(history: _messages.map((m) => Content(m.sender, [TextPart(m.text)])).toList());
    final content = Content.text(text);
    final response = await chat.sendMessage(content);

    if (response.text != null) {
      print(response.text);
      final Map<String, dynamic> data = jsonDecode(response.text!);

      // Check the 'is_event' field.
      if (data['is_event'] == true) {
        // Parse the event object.
        final Map<String, dynamic> event = data['event'];
        final String eventEntry = event['event entry'];
        final String title = event['title'];

        // Display the parsed journal fields along with the response.
        if (kDebugMode) {
          print('Event Entry: $eventEntry');
          print('Title: $title');
          print('Response: ${data['response']}');
        }

        final modelMessage = '${data['response']}\n\nEvent: \n\n Title: $title\n Event Entry: $eventEntry';
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(text: modelMessage, sender: "model"));
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Add Event Entry'),
              content: SingleChildScrollView(child: Text(modelMessage)),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    _saveEventEntry(title, eventEntry);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Only display the response.
        if (kDebugMode) {
          print('Response: ${data['response']}');
        }
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(text: data['response'], sender: "model"));
        });
      }
    }

    setState(() {});
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Planning Chat')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ListView.builder(controller: _scrollController, itemCount: _messages.length, itemBuilder: (context, index) => ChatBubble(message: _messages[index])),
                          if (!_isAtBottom)
                            Positioned(bottom: 10, left: 0, right: 0, child: Center(child: FloatingActionButton(onPressed: _scrollToBottom, mini: true, child: const Icon(Icons.arrow_downward)))),
                        ],
                      ),
                    ),
                    _buildTextComposer(),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 1.0))),
      child: Row(
        children: [
          Flexible(child: TextField(controller: _textController, onSubmitted: _handleSubmitted, decoration: const InputDecoration.collapsed(hintText: 'Send a message'))),
          Container(margin: const EdgeInsets.symmetric(horizontal: 4.0), child: IconButton(icon: const Icon(Icons.send), onPressed: () => _handleSubmitted(_textController.text))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final String sender;
  ChatMessage({required this.text, required this.sender});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  void _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to copy: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == "user";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(10.0)),
                  child: SelectableText(message.text),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: IconButton(icon: const Icon(Icons.copy, size: 16), color: Theme.of(context).colorScheme.primary, onPressed: () => _copyToClipboard(context, message.text), tooltip: "Copy"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
