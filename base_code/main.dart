import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
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

  final String systemPrompt = 
      "You are LuneGPT, an Elite Intelligence and logical peer optimized by Adam Aghnia. "
      "1. [PATTERN RECOGNITION] 2. [LOGICAL VALIDATION] 3. [CLARITY REFINEMENT]. "
      "Professionalism: No slang. Calm, brilliant tone.";

  @override
  void initState() {
    super.initState();
    _bootLune();
  }

  Future<void> _bootLune() async {
    try {
      // 1. Request special "All Files" access for Android 11+ to read from Downloads
      var status = await Permission.manageExternalStorage.request();
      
      if (status.isGranted) {
        // 2. Direct path to your phone's main Downloads folder
        const String downloadPath = "/storage/emulated/0/Download/LuneGPT_Universal.gguf";
        final File modelFile = File(downloadPath);

        if (!modelFile.existsSync()) {
          setState(() => _status = "FILE NOT FOUND IN DOWNLOADS");
          _showPathDialog(downloadPath);
          return;
        }

        setState(() => _status = "LOADING FROM DOWNLOADS...");
        
        // FIXED PARAMETER: threads instead of nThreads
        await _llama.loadModel(
          modelPath: downloadPath, 
          threads: 8,       
          contextSize: 4096,
        );

        setState(() { 
          _isReady = true; 
          _status = "🌙 LUNEGPT ACTIVE"; 
        });
      } else {
        setState(() => _status = "PERMISSION DENIED");
        // Open settings if permission is permanently denied
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    } catch (e) {
      setState(() => _status = "BOOT ERROR: $e");
    }
  }

  void _showPathDialog(String path) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Action Required"),
        content: SelectableText("Ensure the model is named correctly and located at:\n\n$path"),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  void _sendMessage() {
    final userText = _input.text.trim();
    if (userText.isEmpty || !_isReady || _isGenerating) return;

    _input.clear();
    setState(() {
      _isGenerating = true;
      _messages.add({"r": "u", "t": userText});
      _messages.add({"r": "l", "t": ""});
    });

    final prompt = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n$systemPrompt<|eot_id|>"
                   "<|start_header_id|>user<|end_header_id|>\n\n$userText<|eot_id|>"
                   "<|start_header_id|>assistant<|end_header_id|>\n\n";

    String buffer = "";
    _llama.generate(prompt: prompt).listen(
      (token) {
        buffer += token;
        setState(() => _messages.last["t"] = buffer);
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, 
              duration: const Duration(milliseconds: 50), curve: Curves.easeOut);
        }
      },
      onDone: () => setState(() => _isGenerating = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("LUNEGPT", style: TextStyle(letterSpacing: 2, fontSize: 16)),
            Text(_status, style: TextStyle(fontSize: 8, color: _isReady ? Colors.cyanAccent : Colors.red)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_messages[i]["t"]!),
                  ),
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _inputBar() {
    // SafeArea prevents collision with the phone's built-in navigation bar/buttons
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          bottom: 10, // Base padding
          left: 15, 
          right: 15, 
          top: 10
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: "Enter Query...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _isReady ? _sendMessage : null, 
              icon: const Icon(Icons.bolt)
            ),
          ],
        ),
      ),
    );
  }
}
