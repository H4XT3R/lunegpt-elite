import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() {
  runApp(const LlamaApp());
}

class LlamaApp extends StatelessWidget {
  const LlamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
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
  final LlamaController _llama = LlamaController();
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoaded = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      // FIX: Parameters in 0.1.1 use 'threads' NOT 'nThreads'
      await _llama.loadModel(
        modelPath: '/sdcard/Download/model.gguf', // Adjust to your model path
        threads: 4, 
        contextSize: 2048,
      );
      setState(() => _isLoaded = true);
    } catch (e) {
      debugPrint("Init Error: $e");
    }
  }

  void _send() {
    final prompt = _textController.text.trim();
    if (prompt.isEmpty || !_isLoaded) return;

    setState(() {
      _messages.add({"role": "user", "text": prompt});
      _messages.add({"role": "llama", "text": ""});
      _isTyping = true;
    });
    _textController.clear();

    String response = "";
    _llama.generate(prompt: prompt, maxTokens: 512).listen((token) {
      response += token;
      setState(() {
        _messages.last["text"] = response;
      });
    }, onDone: () => setState(() => _isTyping = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Llama Assistant"),
        centerTitle: true,
        actions: [
          Icon(Icons.circle, size: 12, color: _isLoaded ? Colors.green : Colors.red),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _buildBubble(_messages[i]),
            ),
          ),
          if (_isTyping) const LinearProgressIndicator(minHeight: 2),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, String> msg) {
    bool isUser = msg["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg["text"]!,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Type a prompt...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.indigo,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoaded ? _send : null,
            ),
          ),
        ],
      ),
    );
  }
}
