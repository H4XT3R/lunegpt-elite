import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() {
  // Ensure Flutter is initialized before trying to find paths
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LuneGPTApp());
}

class LuneGPTApp extends StatelessWidget {
  const LuneGPTApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyanAccent,
        fontFamily: 'monospace', // Gives it the "Architect" feel
      ),
      home: const LuneChatScreen(),
    );
  }
}

class LuneChatScreen extends StatefulWidget {
  const LuneChatScreen({super.key});
  @override
  State<LuneChatScreen> createState() => _LuneChatScreenState();
}

class _LuneChatScreenState extends State<LuneChatScreen> {
  final LlamaController _llama = LlamaController();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  
  final List<Map<String, String>> _messages = [];
  bool _isReady = false;
  bool _isGenerating = false;
  String _status = "INITIALIZING ARCHITECTURE...";

  // YOUR SYSTEM LOGIC - KEPT EXACTLY FROM COLAB
  final String systemPrompt = 
      "You are LuneGPT, an Elite Intelligence and logical peer optimized by Adam Aghnia. "
      "Your goal is to provide high-precision, professional, and human-centric assistance. "
      "--- CORE REASONING ENGINE --- "
      "1. [PATTERN RECOGNITION] 2. [LOGICAL VALIDATION] 3. [CLARITY REFINEMENT]. "
      "Professionalism: No slang/emojis. Calm, brilliant tone. Conciseness: Fewest words possible.";

  @override
  void initState() {
    super.initState();
    _bootLune();
  }

  Future<void> _bootLune() async {
    try {
      // Find the App-Specific folder (No special permissions required)
      final Directory? extDir = await getExternalStorageDirectory();
      final String modelPath = "${extDir!.path}/LuneGPT_Universal.gguf";

      if (!File(modelPath).existsSync()) {
        setState(() => _status = "MISSING WEIGHTS: PLACE GGUF IN APP FILES");
        _showPathDialog(modelPath);
        return;
      }

      setState(() => _status = "SYNCING NEURAL WEIGHTS...");
      
      // LOAD MODEL - High Performance for 16GB RAM
      await _llama.loadModel(
        modelPath: modelPath, 
        nThreads: 8,       // Utilizing your phone's multi-core CPU
        contextSize: 4096, // Matches your Colab context
      );

      setState(() {
        _isReady = true;
        _status = "🌙 LUNEGPT | NEURO-SYNC ACTIVE";
      });
    } catch (e) {
      setState(() => _status = "BOOT ERROR: $e");
    }
  }

  void _showPathDialog(String path) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("File Setup Required"),
        content: SelectableText("Please move your GGUF file to this exact path:\n\n$path"),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  void _generateResponse() {
    final userText = _input.text.trim();
    if (userText.isEmpty || !_isReady || _isGenerating) return;

    _input.clear();
    setState(() {
      _isGenerating = true;
      _messages.add({"r": "user", "t": userText});
      _messages.add({"r": "lune", "t": ""}); // Placeholder for stream
    });

    // LLAMA 3.2 PROMPT FORMATTING (Preserves system instructions)
    final fullPrompt = 
        "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n$systemPrompt<|eot_id|>"
        "<|start_header_id|>user<|end_header_id|>\n\n$userText<|eot_id|>"
        "<|start_header_id|>assistant<|end_header_id|>\n\n";

    String responseBuffer = "";
    _llama.generate(prompt: fullPrompt).listen(
      (token) {
        responseBuffer += token;
        setState(() => _messages.last["t"] = responseBuffer);
        
        // Dynamic scroll to bottom
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, 
              duration: const Duration(milliseconds: 50), curve: Curves.easeOut);
        }
      },
      onDone: () => setState(() => _isGenerating = false),
      onError: (e) => setState(() { _isGenerating = false; _status = "STREAM ERROR: $e"; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 10,
        shadowColor: Colors.cyanAccent.withOpacity(0.2),
        title: Column(
          children: [
            const Text("LUNEGPT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)),
            Text(_status, style: TextStyle(fontSize: 8, color: _isReady ? Colors.cyanAccent : Colors.redAccent, letterSpacing: 1)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                bool isUser = _messages[i]["r"] == "user";
                return _buildMessageBubble(isUser, _messages[i]["t"]!);
              },
            ),
          ),
          if (_isGenerating) const LinearProgressIndicator(minHeight: 1, backgroundColor: Colors.transparent),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1A2A2F) : const Color(0xFF121212),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isUser ? 15 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 15),
          ),
          border: Border.all(color: isUser ? Colors.cyanAccent.withOpacity(0.3) : Colors.white10),
        ),
        child: Text(
          text.isEmpty && !isUser ? "..." : text,
          style: TextStyle(color: isUser ? Colors.white : Colors.cyanAccent.withOpacity(0.9), fontSize: 14, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        left: 20, right: 20, top: 15
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: (_) => _generateResponse(),
              decoration: InputDecoration(
                hintText: "TRANSMIT QUERY...",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0F0F0F),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: _isReady && !_isGenerating ? _generateResponse : null,
            backgroundColor: _isReady ? Colors.cyanAccent : Colors.grey,
            child: const Icon(Icons.bolt, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
