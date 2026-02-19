import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LuneGPTFinal(),
    ));

class LuneGPTFinal extends StatefulWidget {
  const LuneGPTFinal({super.key});
  @override
  State<LuneGPTFinal> createState() => _LuneGPTFinalState();
}

class _LuneGPTFinalState extends State<LuneGPTFinal> with WidgetsBindingObserver {
  // 1. Initialize Engine
  final LlamaController _llama = LlamaController();
  final TextEditingController _input = TextEditingController();
  final List<Map<String, String>> _chat = [];
  StreamSubscription? _streamSub;
  
  bool _isReady = false;
  bool _isThinking = false;
  String _status = "READY";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamSub?.cancel();
    _llama.dispose(); 
    super.dispose();
  }

  // 2. The "Redmi Survival" Logic: Release RAM when app is hidden
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _llama.unloadModel(); // Frees the 700MB so the OS doesn't kill the app
      setState(() {
        _isReady = false;
        _status = "RAM RELEASED (PAUSED)";
      });
    }
  }

  // 3. Inference Engine Workflow
  Future<void> _load() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _isThinking = true;
        _status = "MAPPING GGUF...";
      });

      try {
        await _llama.loadModel(
          modelPath: result.files.single.path!,
          nThreads: 4,        // Optimal for Helio G91 (4 Big cores)
          contextSize: 512,   // Safe zone for 4GB RAM phones
        );

        setState(() {
          _isReady = true;
          _isThinking = false;
          _status = "🌙 LUNEGPT ONLINE";
        });
      } catch (e) {
        setState(() {
          _isThinking = false;
          _status = "CRASH: $e";
        });
      }
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_isReady || _isThinking) return;

    _input.clear();
    setState(() {
      _chat.add({"r": "u", "m": text});
      _chat.add({"r": "l", "m": ""});
      _isThinking = true;
    });

    // Llama-3 / ChatML Format
    final prompt = "<|start_header_id|>user<|end_header_id|>\n\n$text<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n";

    _streamSub = _llama.generate(prompt: prompt).listen(
      (token) => setState(() => _chat.last["m"] = _chat.last["m"]! + token),
      onDone: () => setState(() => _isThinking = false),
      onError: (e) {
        _llama.stop();
        setState(() => _isThinking = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_status, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: _isReady ? _buildChat() : _buildInit()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInit() => Center(
    child: _isThinking 
      ? const CircularProgressIndicator(color: Colors.cyanAccent)
      : ElevatedButton(onPressed: _load, child: const Text("START ENGINE")),
  );

  Widget _buildChat() => ListView.builder(
    padding: const EdgeInsets.all(15),
    itemCount: _chat.length,
    itemBuilder: (c, i) => Align(
      alignment: _chat[i]["r"] == "u" ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _chat[i]["r"] == "u" ? Colors.cyanAccent.withOpacity(0.1) : Colors.white10,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _chat[i]["r"] == "u" ? Colors.cyanAccent : Colors.transparent),
        ),
        child: Text(_chat[i]["m"]!, style: const TextStyle(color: Colors.white)),
      ),
    ),
  );

  Widget _buildInput() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter command...",
                fillColor: Colors.white10,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isThinking ? Colors.red : Colors.cyanAccent,
            child: IconButton(
              icon: Icon(_isThinking ? Icons.stop : Icons.send, color: Colors.black),
              onPressed: _isThinking ? () => _llama.stop() : _send,
            ),
          )
        ],
      ),
    ),
  );
}
