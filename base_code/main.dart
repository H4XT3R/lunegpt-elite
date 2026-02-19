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
  // 1. Setup Controller
  final LlamaController _llama = LlamaController();
  final TextEditingController _input = TextEditingController();
  final List<Map<String, String>> _chat = [];
  StreamSubscription? _streamSub;
  
  bool _isReady = false;
  bool _isThinking = false;
  String _status = "OFFLINE";

  @override
  void initState() {
    super.initState();
    // Watch for the app closing to save RAM
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamSub?.cancel();
    _llama.dispose(); // This is the correct way to clear RAM in 0.1.1
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If you minimize the app, we shut down the engine to stop the crash
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _llama.dispose();
      setState(() {
        _isReady = false;
        _status = "ENGINE SLEEPING (RAM SAVED)";
      });
    }
  }

  // 2. The Fixed Inference Workflow
  Future<void> _initializeEngine() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _isThinking = true;
        _status = "🧠 LOADING Q4_K_M...";
      });
      try {
        // FIXED: Using 'threads' and 'contextSize' as per 0.1.1 documentation
        await _llama.loadModel(
          modelPath: result.files.single.path!,
          threads: 4,         // Optimal for Helio G91
          contextSize: 512,    // Keeping it small for budget stability
        );

        setState(() {
          _isReady = true;
          _isThinking = false;
          _status = "🌙 LUNEGPT ACTIVE";
        });
      } catch (e) {
        setState(() {
          _isThinking = false;
          _status = "SYNC ERROR: $e";
        });
      }
    }
  }

  void _stopGeneration() async {
    await _llama.stop(); 
    await _streamSub?.cancel(); 
    setState(() {
      _isThinking = false;
      _status = "HALTED";
    });
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

    final prompt = "<|start_header_id|>user<|end_header_id|>\n\n$text<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n";

    _streamSub = _llama.generate(prompt: prompt).listen(
      (token) {
        setState(() => _chat.last["t"] = _chat.last["t"]! + token);
      },
      onDone: () => setState(() => _isThinking = false),
      onError: (e) => _stopGeneration(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_status, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, letterSpacing: 2)),
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
          : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: _initializeEngine, 
              child: const Text("INITIALIZE ENGINE", style: TextStyle(color: Colors.black))
            ),
    );
  }

  Widget _buildChat() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _chat.length,
      itemBuilder: (ctx, i) {
        bool isU = _chat[i]["r"] == "u";
        return Align(
          alignment: isU ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isU ? Colors.cyanAccent.withOpacity(0.1) : Colors.white10,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isU ? Colors.cyanAccent : Colors.transparent),
            ),
            child: Text(_chat[i]["t"]!, style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return SafeArea( // PUSHES INPUT ABOVE SYSTEM BUTTONS
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter neural command...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isThinking ? _stopGeneration : _send,
              child: CircleAvatar(
                backgroundColor: _isThinking ? Colors.redAccent : Colors.cyanAccent,
                child: Icon(_isThinking ? Icons.stop : Icons.bolt, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
