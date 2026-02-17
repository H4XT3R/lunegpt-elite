import 'package:flutter/material.dart';

void main() => runApp(const LuneGPTApp());

class LuneGPTApp extends StatelessWidget {
  const LuneGPTApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: Colors.blueAccent,
      ),
      home: const ChatUI(),
    );
  }
}

class ChatUI extends StatefulWidget {
  const ChatUI({super.key});
  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final List<Map<String, String>> _history = []; // CHAT HISTORY
  final TextEditingController _input = TextEditingController();

  void _send() {
    if (_input.text.isEmpty) return;
    setState(() {
      _history.add({"role": "user", "content": _input.text});
      _history.add({"role": "ai", "content": "Analyzing with LuneGPT Elite..."});
    });
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LuneGPT Elite"), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, i) {
                bool isUser = _history[i]["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(_history[i]["content"]!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _input,
              decoration: InputDecoration(
                hintText: "Enter command...",
                suffixIcon: IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
