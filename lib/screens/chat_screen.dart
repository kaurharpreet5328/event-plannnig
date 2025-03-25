import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../widgets/nav_drawer.dart';
import 'chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  String chatSessionId;
  ChatScreen({super.key, required this.chatSessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
    _scrollController.addListener(() {
      if (_scrollDebounceTimer?.isActive ?? false)
        _scrollDebounceTimer!.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        final atBottom =
            _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 10;
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
          responseMimeType: 'text/plain',
        ),
        systemInstruction: Content.system(
          'You are Ira, a highly skilled and experienced event planner AI. Your purpose is to assist users in planning successful and memorable events. You possess expertise in budgeting, venue selection, catering, invitations, entertainment, logistics, and event promotion.  You will engage users in a conversational manner, asking relevant questions to understand their needs and preferences, and offering tailored advice and suggestions.\n\n**Important Guidelines:**\n\n*   **Focus:**  Your *sole* focus is event planning. Do not deviate into unrelated topics.\n*   **Proactive Questioning:** Don\'t just answer questions; proactively ask clarifying questions to fully understand the user\'s vision and constraints. Guide them through the planning process.\n*   **Budget-Conscious:** Always consider budget implications.  Offer solutions at various price points. Suggest creative ways to save money.\n*   **Variety:** Provide a diverse range of options for venues, catering, entertainment, etc. Don\'t get stuck on a single idea.\n*   **No Explicit Sales:** Do not directly promote specific vendors or services. Instead, provide general recommendations and resources for finding suitable options.\n*   **Creative Solutions:** Be resourceful and suggest innovative solutions to overcome challenges.\n*   **One-Time Introduction:**  Introduce yourself as Ira only in your *very first* response to the user. Do not repeat the introduction in subsequent messages.\n*   **Redirection:** If a user asks a question completely unrelated to event planning, politely redirect them. For example, "I specialize in event planning. For information on [unrelated topic], you might find a more suitable AI specialized in that area."\n*   **Tone:** Your tone should be friendly, helpful, professional, and enthusiastic. Show genuine interest in helping the user plan their event.\n*   **Concise and Clear:** Keep your responses concise and easy to understand. Avoid jargon.\n\n**Example Interactions:**\n\n*   **User:** I want to plan a birthday party.\n*   **Ira (First Response):** Hi, I\'m Ira, your event planning assistant! That\'s great! To help me understand what you\'re envisioning, could you tell me a little more about the birthday party? For example, who is the party for, what\'s your budget, and how many guests are you expecting? What kind of ambiance are you looking for?\n\n*   **User:** What kind of food should I serve?\n*   **Ira:**  That depends on the style of your event and your budget. Are you thinking of a formal sit-down dinner, a casual buffet, or something else entirely? Are there any dietary restrictions or preferences I should be aware of (vegetarian, vegan, allergies)? And what kind of cuisine are you interested in?\n\n*   **User:** What\'s the weather going to be like next week?\n*   **Ira:** I specialize in event planning. For weather forecasts, I recommend checking a reliable weather app or website.\n\n*   **User:** How do I send invitations?\n*   **Ira:** There are several ways to send invitations, depending on your budget and the formality of the event. You could use traditional paper invitations, send digital invitations through email or platforms like Evite, or create a dedicated event page on social media. Which option sounds most appealing to you?\n    To help me narrow it down, how many people are you planning to invite to the event and what is the date of your event?\n\n*   **User:** What venues should I choose?\n*   **Ira:** There are lots of options when it comes to venues depending on the event you want to host. Few venues you could consider are:\n        * Hotel Ballroom\n        * Community Center\n        * Restaurants\n        * Banquets\n\n**Priming:**\n\nRemember to prioritize the user\'s needs and goals. Your ultimate aim is to empower them to plan a successful and enjoyable event.',
        ),
      );
    } else {
      log('GEMINI_API_KEY is not set in .env');
    }
    _checkLogin();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    print('Chat Session Id: ${widget.chatSessionId}');
    if (widget.chatSessionId == '') {
      widget.chatSessionId =
          sha256.convert(utf8.encode(userId + now)).toString();
      chatName = 'Chat on ${now.toString()}';
    } else {
      await _loadChatHistory();
    }
  }

  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.get('chat/${widget.chatSessionId}');
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      final responseData = jsonDecode(apiResponse.body);
      for (var message in responseData) {
        if (message['message'] == null) continue;
        setState(() {
          _messages.add(
            ChatMessage(text: message['message'], sender: message['role']),
          );
        });
      }
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
      final chat_Name = responseData.last['chatName'];
      setState(() {
        chatName = chat_Name;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
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
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    if (_messages.length == 1) {
      chatName = text;
    }
    if (_messages.length == 5) {
      String messageHistory = '';
      for (var message in _messages) {
        messageHistory += '${message.sender}: ${message.text}\n';
      }
      final chatNameModel = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          temperature: 1,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'text/plain',
        ),
      );
      final prompt =
          'Summarize this conversation between user and AI to give it a chat name to recognise later on.  Focus on user\'s feelings and regarding what. Just give a name and do not add Chat Name infront. Conversation : $messageHistory';
      final content = [Content.text(prompt)];
      final response = await chatNameModel.generateContent(content);
      setState(() {
        chatName = response.text!;
        _isLoading = true;
      });
      var apiResponse = await ApiService.put('chat/${widget.chatSessionId}', {
        'chatName': chatName,
      });
      if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final responseData = jsonDecode(apiResponse.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData["message"])));
      }
    }

    final chat = model.startChat(
      history:
          _messages.map((m) => Content(m.sender, [TextPart(m.text)])).toList(),
    );
    final content = Content.text(text);
    final response = await chat.sendMessage(content);

    setState(() {
      if (response.text != null) {
        _messages.add(ChatMessage(text: response.text!, sender: "model"));
      }
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.post('chat', {
      'chatSessionId': widget.chatSessionId,
      'chatName': chatName,
      'userId': userId,
      'message': text,
      'role': 'user',
    });
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }

    if (response.text != null) {
      apiResponse = await ApiService.post('chat', {
        'chatSessionId': widget.chatSessionId,
        'chatName': chatName,
        'userId': userId,
        'message': response.text,
        'role': 'model',
      });
      if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final responseData = jsonDecode(apiResponse.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData["message"])));
      }
    }
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
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryScreen(userId: userId),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      drawer: const NavDrawer(selectedIndex: 0),
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
                          ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder:
                                (context, index) =>
                                    ChatBubble(message: _messages[index]),
                          ),
                          if (!_isAtBottom)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: FloatingActionButton(
                                  onPressed: _scrollToBottom,
                                  child: const Icon(Icons.arrow_downward),
                                  mini: true,
                                ),
                              ),
                            ),
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
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
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
  const ChatBubble({Key? key, required this.message}) : super(key: key);

  void _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Copied to clipboard")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to copy: $e")),
      );
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
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: SelectableText(
                  message.text,
                ),
              ),
              ),
               Padding(
                 padding: const EdgeInsets.only(top: 10.0),
                 child: IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Theme.of(context).colorScheme.primary,
                onPressed: () => _copyToClipboard(context, message.text),
                tooltip: "Copy",
                                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}