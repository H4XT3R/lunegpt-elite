import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'dart:async';

void main() {
  runApp(const LlamaApp());
}

class LlamaApp extends StatelessWidget {
  const LlamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // FIX: Version 0.1.1 uses LlamaController
  final LlamaController _controller = LlamaController();
  final TextEditingController _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoaded = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initLlama();
  }

  Future<void> _initLlama() async {
    try {
      // FIX: Parameters in 0.1.1 are: modelPath, nThreads, contextSize
      // Note the 'n' in nThreads is back in this specific controller method
      await _controller.loadModel(
        modelPath: '/sdcard/Download/model.gguf', // Update to your path
        nThreads: 4, 
        contextSize: 2048,
      );
      setState(() => _isLoaded = true);
    } catch (e) {
      debugPrint("Load error: $e");
    }
  }

  void _sendPrompt() {
    final text = _inputController.text.trim();
    if (text.isEmpty || !_isLoaded) return;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _messages.add(ChatMessage("", false)); // Placeholder for AI response
      _isTyping = true;
    });
    _inputController.clear();

    String fullResponse = "";
    _controller.generate(prompt: text, maxTokens: 512).listen(
      (token) {
        fullResponse += token;
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(fullResponse, false);
        });
      },
      onDone: () => setState(() => _isTyping = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Llama AI Assistant"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.circle, color: _isLoaded ? Colors.green : Colors.grey, size: 12),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _buildChatBubble(_messages[i]),
            ),
          ),
          if (_isTyping) const LinearProgressIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          msg.text,
          style: TextStyle(color: msg.isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(hintText: "Type your message..."),
            ),
          ),
          IconButton(onPressed: _sendPrompt, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}
