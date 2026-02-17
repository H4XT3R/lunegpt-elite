import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(const LuneGPTApp());

class LuneGPTApp extends StatelessWidget {
  const LuneGPTApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        primaryColor: Colors.blueAccent,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final LlamaController _llama = LlamaController();
  
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _checkAndDownloadModel();
  }

  // 📥 AUTOMATIC BRAIN DOWNLOADER
  Future<void> _checkAndDownloadModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/model.gguf');

    if (await file.exists()) {
      _loadModel(file.path);
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // Direct high-speed download for Llama 3.2 1B (~800MB)
      const url = "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf";
      await Dio().download(url, file.path, onReceiveProgress: (count, total) {
        setState(() => _progress = count / total);
      });
      _loadModel(file.path);
    } catch (e) {
      debugPrint("Download failed: $e");
    }
  }

  Future<void> _loadModel(String path) async {
    await _llama.loadModel(modelPath: path);
    setState(() {
      _isDownloading = false;
      _ready = true;
      _messages.insert(0, {"role": "ai", "content": "Brain connected. I am LuneGPT Elite."});
    });
  }

  void _sendMessage() {
    if (!_ready || _controller.text.isEmpty) return;
    String userText = _controller.text;
    setState(() {
      _messages.insert(0, {"role": "user", "content": userText});
      _messages.insert(0, {"role": "ai", "content": "..."});
    });
    _controller.clear();

    String response = "";
    _llama.generateChat(
      messages: _messages.reversed.map((m) => ChatMessage(role: m['role']!, content: m['content']!)).toList(),
      template: 'chatml',
    ).listen((token) {
      setState(() {
        response += token;
        _messages[0]["content"] = response;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LUNEGPT ELITE", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isDownloading ? _buildDownloader() : _buildChat(),
    );
  }

  Widget _buildDownloader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text("Fetching Intelligence...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: _progress, minHeight: 12, backgroundColor: Colors.white10),
            ),
            const SizedBox(height: 10),
            Text("${(_progress * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.blueAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true, // Pushes messages to sit right above the keyboard
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              bool isUser = _messages[i]["role"] == "user";
              return _buildBubble(_messages[i]["content"]!, isUser);
            },
          ),
        ),
        _buildInput(),
      ],
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : const Color(0xFF1E2129),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isUser ? 15 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 15),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 25),
      decoration: const BoxDecoration(color: Color(0xFF1A1D25)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Enter command...",
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white, size: 20)),
          ),
        ],
      ),
    );
  }
}
