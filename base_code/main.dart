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
  StreamSubscription? _streamSub;
  
  bool _isReady = false;
  bool _isThinking = false;
  String _status = "OFFLINE";

  @override
  void initState() {
    super.initState();
    // This part tells the app to watch if you close it
    WidgetsBinding.instance.addObserver(this);
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
    // AUTO-KILL: If you swipe the app away, it kills the model to save your RAM
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _llama.dispose();
      setState(() {
        _isReady = false;
        _status = "ENGINE SLEEPING (RAM SAVED)";
      });
    }
  }

  Future<void> _initializeEngine() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _isThinking = true;
        _status = "🧠 LOADING NEURAL NET...";
      });
      try {
        await _llama.loadModel(
          modelPath: result.files.single.path!,
          // 'threads' is the correct name in the new version
          threads: 4, 
          contextSize: 1024,
        );
        setState(() {
          _isReady = true;
          _isThinking = false;
          _status = "🌙 LUNEGPT ACTIVE";
        });
      } catch (e) {
        setState(() {
          _isThinking = false;
          _status = "CRITICAL SYNC ERROR";
        });
      }
    }
  }

  // STOP GENERATION FUNCTION
  void _stopGeneration() async {
    await _llama.stop(); 
    await _streamSub?.cancel(); 
    setState(() {
      _isThinking = false;
      _status = "GENERATION HALTED";
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_isReady || _isThinking) return;

    _input.clear();
    setState(() {
      _chat.add({"role": "user", "text": text});
      _chat.add({"role": "lune", "text": ""});
      _isThinking = true;
    });

    final prompt = "<|start_header_id|>system<|end_header_id|>\n\n"
        "You are LuneGPT by Adam Aghnia.<|eot_id|>"
        "<|start_header_id|>user<|end_header_id|>\n\n$text<|eot_id|>"
        "<|start_header_id|>assistant<|end_header_id|>\n\n";

    _streamSub = _llama.generate(prompt: prompt).listen(
      (token) {
        setState(() => _chat.last["text"] = _chat.last["text"]! + token);
      },
      onDone: () => setState(() {
        _isThinking = false;
        _status = "🌙 LUNEGPT ACTIVE";
      }),
      onError: (e) => setState(() => _isThinking = false),
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
        elevation: 0,
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
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 50, color: Colors.cyanAccent),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                  onPressed: _initializeEngine, 
                  child: const Text("INITIALIZE ENGINE", style: TextStyle(color: Colors.black))
                ),
              ],
            ),
    );
  }

  Widget _buildChat() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _chat.length,
      itemBuilder: (ctx, i) {
        bool isU = _chat[i]["role"] == "user";
        return Align(
          alignment: isU ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isU ? Colors.cyanAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isU ? Colors.cyanAccent : Colors.white10),
            ),
            child: Text(_chat[i]["text"]!, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    // SafeArea prevents collision with phone's navigation bar/buttons
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Button toggles between "Send" (Bolt) and "Stop" (Square)
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
