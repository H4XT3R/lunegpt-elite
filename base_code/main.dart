import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart'; // The Brain
import 'dart:io';

void main() => runApp(MaterialApp(
  home: LuneGPTBrain(), 
  theme: ThemeData.dark(),
  debugShowCheckedModeBanner: false,
));

class LuneGPTBrain extends StatefulWidget {
  @override
  _LuneGPTBrainState createState() => _LuneGPTBrainState();
}

class _LuneGPTBrainState extends State<LuneGPTBrain> {
  // AI Variables
  LlamaController? _llama;
  final TextEditingController _input = TextEditingController();
  final List<String> _chatHistory = [];
  final ScrollController _scroll = ScrollController();
  
  // Status Variables
  String status = "🌙 Moon Base Connecting...";
  String debugLog = "System: Initializing...";
  double progress = 0.0;
  bool isReady = false;
  bool isThinking = false;

  @override
  void initState() {
    super.initState();
    _startIntelligenceFetch();
  }

  void log(String msg) => setState(() => debugLog = "$msg\n$debugLog");

  Future<void> _startIntelligenceFetch() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/brain.gguf');

      if (!await file.exists()) {
        // --- DOWNLOAD PHASE ---
        const url = "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q2_K.gguf";
        log("📡 Downloading Neural Network...");
        
        final dio = Dio(BaseOptions(followRedirects: true, maxRedirects: 5));
        await dio.download(url, file.path, onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              progress = count / total;
              status = "Downloading Brain: ${(progress * 100).toStringAsFixed(1)}%";
            });
          }
        });
      }

      // --- LOADING PHASE ---
      setState(() => status = "Loading Neural Matrix...");
      log("🧠 Loading GGUF Model...");
      
      _llama = LlamaController();
      await _llama!.loadModel(
        modelPath: file.path,
        contextSize: 2048, // Short-term memory
        nThreads: 4,       // CPU Cores to use
      );

      setState(() { isReady = true; status = "LuneGPT Online"; });
      log("✅ AI System Active");

    } catch (e) {
      log("❌ CRITICAL ERROR: $e");
      setState(() => status = "System Failure. Check Logs.");
    }
  }

  void _sendMessage() {
    if (_input.text.isEmpty || isThinking || !isReady) return;

    final userText = _input.text;
    setState(() {
      _chatHistory.add("> YOU: $userText");
      _input.clear();
      isThinking = true;
      _chatHistory.add("🌙 LUNE: "); // Placeholder for AI response
    });
    
    // Auto-scroll to bottom
    Future.delayed(Duration(milliseconds: 100), () {
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    });

    // Llama 3.2 Prompt Format
    final prompt = "<|begin_of_text|><|start_header_id|>user<|end_header_id|>\n\n$userText<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n";

    try {
      _llama!.generate(
        prompt: prompt,
        maxTokens: 128, // Limit response length for speed
        temperature: 0.7, // Creativity
      ).listen((token) {
        setState(() {
          // Append token to the last message (LUNE's message)
          _chatHistory.last = _chatHistory.last + token;
        });
        
        // Follow the text as it generates
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }, onDone: () {
        setState(() => isThinking = false);
      });
    } catch (e) {
      log("Generation Error: $e");
      setState(() => isThinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0C10),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.0,
            colors: [Color(0xFF1B2735), Color(0xFF090A0F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- DEBUG CONSOLE (Mini) ---
              Container(
                height: 40,
                width: double.infinity,
                color: Colors.black54,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(debugLog.split('\n').first, style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace')),
              ),

              // --- MAIN INTERFACE ---
              Expanded(
                child: !isReady
                    // LOADING SCREEN
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.nights_stay, size: 80, color: Colors.cyanAccent),
                            SizedBox(height: 30),
                            Container(width: 200, child: LinearProgressIndicator(value: progress, color: Colors.cyanAccent)),
                            SizedBox(height: 20),
                            Text(status, style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      )
                    // CHAT SCREEN
                    : ListView.builder(
                        controller: _scroll,
                        padding: EdgeInsets.all(20),
                        itemCount: _chatHistory.length,
                        itemBuilder: (ctx, i) {
                          final isUser = _chatHistory[i].startsWith("> YOU:");
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.cyanAccent.withOpacity(0.1) : Colors.black45,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isUser ? Colors.cyanAccent.withOpacity(0.3) : Colors.transparent),
                            ),
                            child: Text(
                              _chatHistory[i].replaceAll("> YOU: ", "").replaceAll("🌙 LUNE: ", ""),
                              style: TextStyle(color: isUser ? Colors.cyanAccent : Colors.white),
                            ),
                          );
                        },
                      ),
              ),

              // --- INPUT BOX ---
              if (isReady)
                Padding(
                  padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: isThinking ? "Thinking..." : "Message LuneGPT...",
                              hintStyle: TextStyle(color: Colors.white24),
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(isThinking ? Icons.hourglass_top : Icons.send_rounded, color: Colors.cyanAccent),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
