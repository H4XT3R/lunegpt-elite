import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyanAccent, brightness: Brightness.dark),
      ),
      home: const LuneGPTElite(),
    ));

class LuneGPTElite extends StatefulWidget {
  const LuneGPTElite({super.key});
  @override
  State<LuneGPTElite> createState() => _LuneGPTEliteState();
}

class _LuneGPTEliteState extends State<LuneGPTElite> {
  final LlamaController _llama = LlamaController();
  final TextEditingController _input = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isReady = false;
  bool _isGenerating = false;
  String _status = "SYSTEM OFFLINE";

  Future<void> _pickAndLoad() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() => _status = "INITIALIZING CORE...");
        await _llama.loadModel(
          modelPath: result.files.single.path!,
          threads: 2,       // Safe for Redmi 14C
          contextSize: 512,  // Low RAM footprint
        );
        setState(() { _isReady = true; _status = "LUNEGPT ONLINE"; });
      }
    } catch (e) {
      setState(() => _status = "CORE ERROR: $e");
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_isReady || _isGenerating) return;
    _input.clear();
    setState(() {
      _isGenerating = true;
      _messages.add({"r": "u", "t": text});
      _messages.add({"r": "l", "t": ""});
    });

    String buffer = "";
    _llama.generate(prompt: text).listen((token) {
      buffer += token;
      setState(() => _messages.last["t"] = buffer);
    }, onDone: () => setState(() => _isGenerating = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(_status, style: const TextStyle(letterSpacing: 2, fontSize: 12, color: Colors.cyanAccent)),
      ),
      body: Column(
        children: [
          if (!_isReady) _buildSetupUI() else _buildChatList(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSetupUI() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.blur_on, size: 100, color: Colors.cyanAccent),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              onPressed: _pickAndLoad,
              child: const Text("INITIALIZE ENGINE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _messages.length,
        itemBuilder: (ctx, i) {
          bool isU = _messages[i]["r"] == "u";
          return Align(
            alignment: isU ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                gradient: isU 
                  ? const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]) 
                  : const LinearGradient(colors: [Color(0xFF232526), Color(0xFF414345)]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isU ? 20 : 0),
                  bottomRight: Radius.circular(isU ? 0 : 20),
                ),
              ),
              child: Text(_messages[i]["t"]!, style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter neural prompt...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: _isReady ? Colors.cyanAccent : Colors.grey[800],
              child: IconButton(
                onPressed: _send,
                icon: Icon(Icons.bolt, color: _isReady ? Colors.black : Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
