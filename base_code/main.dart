import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const LuneGPTApp());

class LuneGPTApp extends StatelessWidget {
  const LuneGPTApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LlamaController _llama = LlamaController();
  bool _isLoaded = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedHistory = prefs.getString('chat_history');
    if (savedHistory != null) {
      setState(() {
        _messages.addAll(List<Map<String, String>>.from(json.decode(savedHistory)));
      });
    }
    // Note: In a real app, you'd load the .gguf file path here
    // await _llama.loadModel(modelPath: 'path/to/your/model.gguf');
    setState(() => _isLoaded = true);
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('chat_history', json.encode(_messages));
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userText = _controller.text;
    setState(() {
      _messages.add({"role": "user", "content": userText});
      _messages.add({"role": "assistant", "content": ""}); // Placeholder for AI
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // AI STREAMING LOGIC
    String aiResponse = "";
    _llama.generateChat(
      messages: _messages.map((m) => ChatMessage(role: m['role']!, content: m['content']!)).toList(),
    ).listen((token) {
      setState(() {
        aiResponse += token;
        _messages.last["content"] = aiResponse;
      });
      _scrollToBottom();
    }, onDone: () {
      setState(() => _isTyping = false);
      _saveHistory();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LuneGPT Elite"), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                bool isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(m['content']!, style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: "Ask LuneGPT...", border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Colors.blueAccent), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
