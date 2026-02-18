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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.cyan,
        brightness: Brightness.dark,
      ),
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

  Future<void> _startUp() async {
    setState(() => _status = "Requesting Storage Access...");
    
    // Request permissions to stop the app from auto-closing
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();

    const String path = '/sdcard/Download/model.gguf';

    if (!File(path).existsSync()) {
      setState(() {
        _loading = false;
        _status = "CRITICAL ERROR: model.gguf not found in Downloads folder.";
      });
      return;
    }

    try {
      setState(() => _status = "Initializing 16GB RAM Bridge...");
      
      // Fixed: nThreads is the correct parameter for v0.1.1
      await _llama.loadModel(
        modelPath: path,
        nThreads: 4, 
        contextSize: 2048,
      );

      setState(() {
        _ready = true;
        _loading = false;
        _status = "System Online";
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = "LOAD FAILED: $e";
      });
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_ready) return;

    setState(() {
      _msgs.add({"role": "user", "text": text});
      _msgs.add({"role": "llama", "text": "..."});
      _ready = false; 
    });
    _input.clear();

    String buffer = "";
    _llama.generate(prompt: text, maxTokens: 512).listen(
      (token) {
        buffer += token;
        setState(() {
          _msgs.last["text"] = buffer;
        });
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      },
      onDone: () => setState(() => _ready = true),
      onError: (e) => setState(() {
        _msgs.last["text"] = "Error: $e";
        _ready = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Llama Factory AI", style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _ready ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(color: _ready ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _msgs.length,
                    itemBuilder: (context, i) => _chatBubble(_msgs[i]),
                  ),
          ),
          _inputPanel(),
        ],
      ),
    );
  }

  Widget _chatBubble(Map<String, String> m) {
    bool isUser = m["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? Colors.cyan[800] : Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(m["text"]!, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _inputPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: "Type a prompt...",
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _ready ? _send : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
