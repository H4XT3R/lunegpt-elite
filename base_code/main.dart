import 'dart:io';
import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const LlamaApp());

class LlamaApp extends StatelessWidget {
  const LlamaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.cyan, brightness: Brightness.dark),
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
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isReady = false;
  String _status = "Checking system...";

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    // Permission request to prevent auto-close
    await [Permission.storage, Permission.manageExternalStorage].request();

    const path = '/sdcard/Download/model.gguf';
    if (!File(path).existsSync()) {
      setState(() => _status = "Model not found in Downloads!");
      return;
    }

    try {
      setState(() => _status = "Loading into 16GB RAM...");
      
      // FIX: Changed 'nThreads' to 'threads' based on your build error
      await _llama.loadModel(
        modelPath: path,
        threads: 4, 
        contextSize: 2048,
      );

      setState(() {
        _isReady = true;
        _status = "Llama Online";
      });
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_isReady) return;

    setState(() {
      _messages.add({"r": "u", "t": text});
      _messages.add({"r": "l", "t": ""});
    });
    _input.clear();

    String response = "";
    _llama.generate(prompt: text).listen((token) {
      response += token;
      setState(() => _messages.last["t"] = response);
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_status, style: const TextStyle(fontSize: 14))),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                bool isUser = _messages[i]["r"] == "u";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.cyan[700] : Colors.grey[850],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(_messages[i]["t"]!),
                  ),
                );
              },
            ),
          ),
          _inputArea(),
        ],
      ),
    );
  }

  Widget _inputArea() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _input, decoration: const InputDecoration(hintText: "Type here..."))),
          IconButton(onPressed: _isReady ? _send : null, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}
