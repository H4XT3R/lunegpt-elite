import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LuneGPTElite(),
    ));

class LuneGPTElite extends StatefulWidget {
  const LuneGPTElite({super.key});
  @override
  State<LuneGPTElite> createState() => _LuneGPTEliteState();
}

class _LuneGPTEliteState extends State<LuneGPTElite> with WidgetsBindingObserver {
  final LlamaController _llama = LlamaController();
  final TextEditingController _input = TextEditingController();
  final List<Map<String, String>> _chat = [];
  StreamSubscription? _streamSub; // To control the text stream
  
  bool _isReady = false;
  bool _isThinking = false;
  String _status = "OFFLINE";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Watch for App Open/Close
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamSub?.cancel();
    _llama.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If you swipe the app away or close it, kill the model to free RAM
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _llama.dispose();
      setState(() => _isReady = false);
    }
  }

  Future<void> _initializeEngine() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _isThinking = true;
        _status = "🧠 SYNCING...";
      });
      try {
        await _llama.loadModel(
          modelPath: result.files.single.path!,
          nThreads: 4,
          contextSize: 1024,
        );
        setState(() {
          _isReady = true;
          _isThinking = false;
          _status = "🌙 LUNEGPT ACTIVE";
        });
      } catch (e) {
        setState(() => _status = "CRITICAL ERROR");
      }
    }
  }

  // STOP GENERATION FUNCTION
  void _stopGeneration() async {
    await _llama.stop(); // Stops the internal C++ engine
    await _streamSub?.cancel(); // Stops the Flutter text updates
    setState(() => _isThinking = false);
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_isReady || _isThinking) return;

    _input.clear();
    setState(() {
      _chat.add({"r": "u", "t": text});
      _chat.add({"r": "l", "t": ""});
      _isThinking = true;
    });

    final prompt = "<|start_header_id|>system<|end_header_id|>\n\n"
        "You are LuneGPT by Adam Aghnia.<|eot_id|>"
        "<|start_header_id|>user<|end_header_id|>\n\n$text<|eot_id|>"
        "<|start_header_id|>assistant<|end_header_id|>\n\n";

    _streamSub = _llama.generate(prompt: prompt).listen(
      (token) {
        setState(() => _chat.last["t"] = _chat.last["t"]! + token);
      },
      onDone: () => setState(() => _isThinking = false),
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
          Expanded(child: _isReady ? _buildChat() : _buildSetup()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSetup() {
    return Center(
      child: _isThinking 
          ? const CircularProgressIndicator(color: Colors.cyanAccent)
          : ElevatedButton(onPressed: _initializeEngine, child: const Text("INIT ENGINE")),
    );
  }

  Widget _buildChat() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _chat.length,
      itemBuilder: (ctx, i) => Align(
        alignment: _chat[i]["r"] == "u" ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _chat[i]["r"] == "u" ? Colors.cyanAccent.withOpacity(0.1) : Colors.white10,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(_chat[i]["t"]!, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea( // Pushes the UI above the phone's navigation bar
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Colors.white10))),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Neural command...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  fillColor: Colors.white.withOpacity(0.05),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Dynamic Button: Switch between Send and Stop
            CircleAvatar(
              backgroundColor: _isThinking ? Colors.redAccent : Colors.cyanAccent,
              child: IconButton(
                icon: Icon(_isThinking ? Icons.stop : Icons.bolt, color: Colors.black),
                onPressed: _isThinking ? _stopGeneration : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
