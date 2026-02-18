import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080809),
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

  Future<void> _pickAndLoad() async {
    try {
      setState(() => _isLoading = true);
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        setState(() => _status = "🧠 SYNCING NEURO-CORE...");
        
        // CRITICAL: Give the UI 1 second to settle so the phone doesn't panic
        await Future.delayed(const Duration(seconds: 1));

        await _llama.loadModel(
          modelPath: result.files.single.path!,
          threads: 1,        // Use 1 thread for maximum stability on Redmi
          contextSize: 256,   // Absolute minimum RAM usage
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
        _status = "SYNC FAILED: PHONE RAM FULL";
      });
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_isReady) return;

    final prompt = "<|start_header_id|>system<|end_header_id|>\n\n"
        "You are LuneGPT, an Elite Intelligence optimized by Adam Aghnia.<|eot_id|>"
        "<|start_header_id|>user<|end_header_id|>\n\n$text<|eot_id|>"
        "<|start_header_id|>assistant<|end_header_id|>\n\n";

    _input.clear();
    setState(() {
      _messages.add({"r": "u", "t": text});
      _messages.add({"r": "l", "t": ""});
    });

    _llama.generate(prompt: prompt).listen((token) {
      setState(() => _messages.last["t"] = _messages.last["t"]! + token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This prevents the keyboard from squishing your UI
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_status, style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
      ),
      body: Column(
        children: [
          Expanded(child: _isReady ? _buildChat() : _buildSetup()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSetup() {
    return Center(
      child: _isLoading 
        ? const CircularProgressIndicator(color: Colors.cyanAccent)
        : ElevatedButton(onPressed: _pickAndLoad, child: const Text("INITIALIZE ENGINE")),
    );
  }

  Widget _buildChat() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _messages[i]["r"] == "u" ? Colors.cyan.withOpacity(0.1) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(_messages[i]["t"]!),
      ),
    );
  }

  Widget _buildInputArea() {
    // SafeArea prevents collision with bottom navigation buttons
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: "Enter prompt...",
                  fillColor: Colors.white10,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            IconButton(onPressed: _send, icon: const Icon(Icons.bolt, color: Colors.cyanAccent)),
          ],
        ),
      ),
    );
  }
}
