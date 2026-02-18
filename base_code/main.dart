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
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.cyan),
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
  
  // Progress tracking variables
  String _status = "STARTING UP...";
  double _migrationProgress = 0.0;
  bool _showProgressBar = false;

  @override
  void initState() {
    super.initState();
    _bootLune();
  }

  Future<void> _bootLune() async {
    try {
      // 1. Permissions check
      if (await Permission.manageExternalStorage.request().isDenied) {
        setState(() => _status = "ERROR: PERMISSION DENIED");
        return;
      }

      final Directory? appDir = await getExternalStorageDirectory();
      final String privatePath = "${appDir!.path}/LuneGPT_Universal.gguf";
      const String downloadPath = "/storage/emulated/0/Download/LuneGPT_Universal.gguf";

      // 2. Check if already migrated
      if (File(privatePath).existsSync()) {
        setState(() => _status = "🧠 LOADING ENGINE...");
        await _loadLlama(privatePath);
        return;
      }

      // 3. Start Migration if found in Downloads
      final File downloadFile = File(downloadPath);
      if (downloadFile.existsSync()) {
        await _migrateWithProgress(downloadFile, privatePath);
      } else {
        setState(() => _status = "📂 MISSING: PLACE GGUF IN DOWNLOADS");
      }
    } catch (e) {
      setState(() => _status = "BOOT ERROR: $e");
    }
  }

  // --- THE PROGRESS BAR LOGIC ---
  Future<void> _migrateWithProgress(File source, String targetPath) async {
    setState(() {
      _status = "🚚 MIGRATING NEURAL CORE...";
      _showProgressBar = true;
    });

    final int totalBytes = await source.length();
    int bytesCopied = 0;

    final File targetFile = File(targetPath);
    final IOSink sink = targetFile.openWrite();

    // Read the file in chunks and update UI progress
    await source.openRead().forEach((chunk) {
      sink.add(chunk);
      bytesCopied += chunk.length;
      setState(() {
        _migrationProgress = bytesCopied / totalBytes;
      });
    });

    await sink.close();
    
    setState(() {
      _showProgressBar = false;
      _status = "✅ MIGRATION COMPLETE";
    });
    
    await _loadLlama(targetPath);
  }

  Future<void> _loadLlama(String path) async {
    await _llama.loadModel(
      modelPath: path,
      threads: 6, // Best for Redmi 14C
      contextSize: 4096,
    );
    setState(() {
      _isReady = true;
      _status = "🌙 LUNEGPT ACTIVE";
    });
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

    String buffer = "";
    _llama.generate(prompt: userText).listen(
      (token) {
        buffer += token;
        setState(() => _messages.last["t"] = buffer);
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
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
            Text(_status, style: TextStyle(fontSize: 10, color: _isReady ? Colors.cyan : Colors.orange)),
            if (_showProgressBar) 
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 40, right: 40),
                child: LinearProgressIndicator(
                  value: _migrationProgress,
                  backgroundColor: Colors.white10,
                  color: Colors.cyan,
                  minHeight: 2,
                ),
              ),
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
                      borderRadius: BorderRadius.circular(15),
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: "Enter Query...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(onPressed: _isReady ? _sendMessage : null, icon: const Icon(Icons.bolt)),
          ],
        ),
      ),
    );
  }
}
