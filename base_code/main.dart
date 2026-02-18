import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() => runApp(MaterialApp(
  home: LuneGPTEngine(), 
  theme: ThemeData.dark(),
  debugShowCheckedModeBanner: false,
));

class LuneGPTEngine extends StatefulWidget {
  @override
  _LuneGPTEngineState createState() => _LuneGPTEngineState();
}

class _LuneGPTEngineState extends State<LuneGPTEngine> {
  String status = "🌙 LuneGPT Awakening...";
  String debugLog = "System: Initializing Neural Links...";
  double progress = 0.0;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _startIntelligenceFetch();
  }

  void log(String msg) => setState(() => debugLog = "${msg}\n$debugLog");

  Future<void> _startIntelligenceFetch() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/brain.gguf');

      if (await file.exists()) {
        setState(() { isReady = true; status = "LuneGPT Online"; });
        return;
      }

      // ✅ FIXED: New Verified Hugging Face Direct Download Link
      const url = "https://huggingface.co/unsloth/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q2_K.gguf?download=true";
      
      log("Connecting to Moon Base...");
      await Dio().download(url, file.path, onReceiveProgress: (count, total) {
        if (total != -1) {
          setState(() {
            progress = count / total;
            status = "Fetching Intelligence: ${(progress * 100).toStringAsFixed(1)}%";
          });
        }
      });

      setState(() { isReady = true; status = "LuneGPT Online"; });
    } catch (e) {
      log("❌ ERROR: $e");
      setState(() => status = "Link Broken. Check Logs.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117), // Deep Space Blue
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.2,
            colors: [Color(0xFF161B22), Color(0xFF0D1117)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- DEBUG CONSOLE ---
              Container(
                height: 70,
                width: double.infinity,
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(debugLog, style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace')),
                ),
              ),

              Expanded(
                child: Center(
                  child: !isReady 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glowy Moon Icon
                          Icon(Icons.dark_mode, size: 100, color: Colors.cyanAccent),
                          SizedBox(height: 30),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 50),
                            child: LinearProgressIndicator(
                              value: progress, 
                              backgroundColor: Colors.white10,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(status, style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.5)),
                        ],
                      )
                    : Icon(Icons.auto_awesome, size: 120, color: Colors.cyanAccent),
              ),

              // --- CHAT BOX (LIFTED HIGHER) ---
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 60), // Extra bottom padding (60) avoids your phone buttons
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                  ),
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Speak to Lune...",
                      hintStyle: TextStyle(color: Colors.white24),
                      contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      border: InputBorder.none,
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.send_rounded, color: Colors.cyanAccent),
                      ),
                    ),
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
