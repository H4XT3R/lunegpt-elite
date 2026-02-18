import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0B),
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
  bool _isLoading = false;
  String _status = "SYSTEM OFFLINE";

  // 1. IMPROVED PICKER: Bypasses the "BIN" error by allowing any extension
  Future<void> _pickAndLoad() async {
    try {
      setState(() => _isLoading = true);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Tells Android to ignore its "BIN" label
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        setState(() => _status = "🧠 SYNCING NEURO-CORE...");

        await _llama.loadModel(
          modelPath: path,
          threads: 2,         // Safe for Redmi 14C
          contextSize: 256,    // Tiny for maximum stability
        );

        setState(() {
          _isReady = true;
          _isLoading = false;
          _status = "🌙 LUNEGPT | NEURO-SYNC ACTIVE";
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = "SYNC ERROR: $e";
      });
    }
  }

  // 2. NEURO-SYNC PROMPT: Matches Adam Aghnia's exact template
  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_isReady) return;

    // Use the exact Llama-3 formatting from the Colab script
    final neuroPrompt = 
      "<|start_header_id|>system<|end_header_id|>\n\n"
      "You are LuneGPT, an Elite Intelligence and logical peer optimized by Adam Aghnia.<|eot_id|>"
      "<|start_header_id|>user<|end_header_id|>\n\n$text<|eot_id|>"
      "<|start_header_id|>assistant<|end_header_id|>\n\n";

    _input.clear();
    setState(() {
      _messages.add({"r": "u", "t": text});
      _messages.add({"r": "l", "t": ""});
    });

    String buffer = "";
    _llama.generate(prompt: neuroPrompt).listen((token) {
      buffer += token;
      setState(() => _messages.last["t"] = buffer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(_status, style: const TextStyle(letterSpacing: 1.5, fontSize: 10, color: Colors.cyanAccent)),
      ),
      body: Column(
        children: [
          if (!_isReady) _buildSetup() else _buildChat(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildSetup() {
    return Expanded(
      child: Center(
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.cyanAccent)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, size: 80, color: Colors.cyanAccent),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                  onPressed: _pickAndLoad,
                  child: const Text("INITIALIZE GGUF ENGINE"),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildChat() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _messages.length,
        itemBuilder: (ctx, i) {
          bool isU = _messages[i]["r"] == "u";
          return Align(
            alignment: isU ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isU ? Colors.cyanAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isU ? Colors.cyanAccent : Colors.white10),
              ),
              child: Text(_messages[i]["t"]!, style: const TextStyle(fontSize: 15)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              decoration: InputDecoration(
                hintText: "Message LuneGPT...",
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          IconButton(
            onPressed: _send,
            icon: const Icon(Icons.bolt, color: Colors.cyanAccent),
          )
        ],
      ),
    );
  }
}
