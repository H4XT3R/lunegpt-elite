import 'dart:io';
import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const LlamaFactoryApp());

class LlamaFactoryApp extends StatelessWidget {
  const LlamaFactoryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.cyan, brightness: Brightness.dark),
      home: const MainChat(),
    );
  }
}

class MainChat extends StatefulWidget {
  const MainChat({super.key});
  @override
  State<MainChat> createState() => _MainChatState();
}

class _MainChatState extends State<MainChat> {
  final LlamaController _llama = LlamaController();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, String>> _msgs = [];
  
  bool _ready = false;
  bool _loading = true;
  String _status = "Starting Engine...";

  @override
  void initState() {
    super.initState();
    _startUp();
  }

  // ALL-IN-ONE SETUP LOGIC
  Future<void> _startUp() async {
    // 1. Request Permissions (Crucial for physical phones)
    setState(() => _status = "Requesting Storage Access...");
    await [Permission.storage, Permission.manageExternalStorage].request();

    // 2. Locate the Model
    const String path = '/sdcard/Download/model.gguf';
    if (!File(path).existsSync()) {
      setState(() {
        _loading = false;
        _status = "CRITICAL ERROR: model.gguf not found in Downloads folder.";
      });
      return;
    }

    // 3. Load Model with v0.1.1 parameters
    try {
      setState(() => _status = "Initializing 16GB RAM Bridge...");
      await _llama.loadModel(
        modelPath: path, 
        nThreads: 6, // Optimized for 8GB+ phones
        contextSize: 2048,
      );
      setState(() { _ready = true; _loading = false; _status = "System Online"; });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = "LOAD FAILED: $e\n\nTip: Ensure 'largeHeap' is true in Manifest.";
      });
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_ready) return;

    setState(() {
      _msgs.add({"r": "user", "t": text});
      _msgs.add({"r": "llama", "t": "..."});
    });
    _input.clear();

    String buffer = "";
    _llama.generate(prompt: text).listen((token) {
      buffer += token;
      setState(() => _msgs.last["t"] = buffer);
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }, onDone: () => setState(() => _ready = true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Llama Factory v0.1.1", style: TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.black12,
      ),
      body: Column(
        children: [
          // Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _ready ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Text(_status, textAlign: TextAlign.center, style: TextStyle(color: _ready ? Colors.green : Colors.orange, fontSize: 12)),
          ),
          
          // Chat Area
          Expanded(
            child: _loading 
              ? Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _msgs.length,
                  itemBuilder: (context, i) => _chatBubble(_msgs[i]),
                ),
          ),

          // Input Area
          _inputPanel(),
        ],
      ),
    );
  }

  Widget _chatBubble(Map<String, String> m) {
    bool isUser = m["r"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? Colors.cyan[700] : Colors.grey[850],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isUser ? Radius.circular(16) : Radius.circular(0),
            bottomRight: isUser ? Radius.circular(0) : Radius.circular(16),
          ),
        ),
        child: Text(m["t"]!, style: TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _inputPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black26),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: _ready ? "Type a prompt..." : "Waiting for model...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[900],
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _ready ? _send : null,
              child: Icon(Icons.send_rounded),
              backgroundColor: _ready ? Colors.cyan : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
