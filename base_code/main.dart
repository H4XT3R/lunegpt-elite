import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: LuneGPTSlowLoad(),
));

class LuneGPTSlowLoad extends StatefulWidget {
  const LuneGPTSlowLoad({super.key});
  @override
  State<LuneGPTSlowLoad> createState() => _LuneGPTSlowLoadState();
}

class _LuneGPTSlowLoadState extends State<LuneGPTSlowLoad> with WidgetsBindingObserver {
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
    _llama.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _llama.dispose(); // Instantly drop the model to keep Android happy
      setState(() => _isReady = false);
    }
  }

  Future<void> _loadModel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _isThinking = true;
        _status = "MAPPING NEURAL CORE...";
      });

      try {
        // THE SECRET: We use very low threads and small context to stay 'slow'
        await _llama.loadModel(
          modelPath: result.files.single.path!,
          threads: 2,        // Lower threads = less "aggression" on the CPU/RAM
          contextSize: 256,   // Very small context is much safer for the Redmi 14C
          // The plugin uses 'useMmap: true' by default, which is what we want!
        );

        setState(() {
          _isReady = true;
          _isThinking = false;
          _status = "🌙 LUNEGPT ACTIVE";
        });
      } catch (e) {
        setState(() {
          _isThinking = false;
          _status = "SYSTEM FAILED";
        });
      }
    }
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
      (token) => setState(() => _chat.last["t"] = _chat.last["t"]! + token),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_status, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: _isReady ? _buildChat() : _buildInit()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInit() => Center(
    child: _isThinking 
      ? const CircularProgressIndicator(color: Colors.cyanAccent)
      : ElevatedButton(onPressed: _loadModel, child: const Text("LOAD MODEL")),
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
        ),
        child: Text(_chat[i]["t"]!, style: const TextStyle(color: Colors.white)),
      ),
    ),
  );

  Widget _buildInputBar() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Neural command...",
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
