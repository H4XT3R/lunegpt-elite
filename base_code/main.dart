import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(const MaterialApp(home: EasyLune()));

class EasyLune extends StatefulWidget {
  const EasyLune({super.key});
  @override
  State<EasyLune> createState() => _EasyLuneState();
}

class _EasyLuneState extends State<EasyLune> {
  final LlamaController _llama = LlamaController();
  final TextEditingController _input = TextEditingController();
  final List<Map<String, String>> _messages = [];
  
  bool _isReady = false;
  bool _isGenerating = false;
  String _status = "STEP 1: TAP BUTTON BELOW";

  // The Magic Button: No Manifest needed!
  Future<void> _pickAndLoad() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        setState(() => _status = "🧠 LOADING ENGINE...");
        
        await _llama.loadModel(
          modelPath: result.files.single.path!,
          threads: 6, // Best for Redmi 14C
          contextSize: 2048,
        );

        setState(() {
          _isReady = true;
          _status = "🌙 LUNEGPT ACTIVE";
        });
      }
    } catch (e) {
      setState(() => _status = "ERROR: $e");
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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(_status, style: const TextStyle(fontSize: 14, color: Colors.cyanAccent)),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!_isReady) 
            Expanded(child: Center(
              child: ElevatedButton.icon(
                onPressed: _pickAndLoad,
                icon: const Icon(Icons.folder),
                label: const Text("SELECT GGUF FROM DOWNLOADS"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[800], foregroundColor: Colors.white),
              ),
            ))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  bool isU = _messages[i]["r"] == "u";
                  return Align(
                    alignment: isU ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isU ? Colors.cyan[900] : Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(_messages[i]["t"]!, style: const TextStyle(color: Colors.white)),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Ask LuneGPT...",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isReady ? _send : null,
              icon: const Icon(Icons.bolt),
              backgroundColor: Colors.cyanAccent,
            ),
          ],
        ),
      ),
    );
  }
}
