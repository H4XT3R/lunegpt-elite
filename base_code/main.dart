import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() => runApp(MaterialApp(
  home: LuneGPTEngine(), 
  theme: ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Color(0xFF0B0E14),
    primaryColor: Colors.cyanAccent,
  ),
  debugShowCheckedModeBanner: false,
));

class LuneGPTEngine extends StatefulWidget {
  @override
  _LuneGPTEngineState createState() => _LuneGPTEngineState();
}

class _LuneGPTEngineState extends State<LuneGPTEngine> {
  String status = "Initializing System...";
  String debugLog = "Logs: Waiting for connection...";
  double progress = 0.0;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _startIntelligenceFetch();
  }

  void log(String msg) => setState(() => debugLog = "${DateTime.now().second}s: $msg\n$debugLog");

  Future<void> _startIntelligenceFetch() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/brain.gguf');

      if (await file.exists()) {
        setState(() { isReady = true; status = "LuneGPT Online"; });
        return;
      }

      const url = "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q2_K.gguf";
      
      log("Connecting to Neural Server...");
      await Dio().download(url, file.path, onReceiveProgress: (count, total) {
        if (total != -1) {
          setState(() {
            progress = count / total;
            status = "Syncing Neural Network: ${(progress * 100).toStringAsFixed(1)}%";
          });
        }
      });

      setState(() { isReady = true; status = "LuneGPT Online"; });
    } catch (e) {
      log("FAIL: $e");
      setState(() => status = "Connection Error. See Logs.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1F2C), Color(0xFF0B0E14)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- DEBUG LOGS ---
              Container(
                height: 80,
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
                child: SingleChildScrollView(
                  reverse: true,
                  padding: EdgeInsets.all(8),
                  child: Text(debugLog, style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace')),
                ),
              ),
              
              Expanded(
                child: Center(
                  child: !isReady 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nights_stay, size: 80, color: Colors.cyanAccent.withOpacity(0.5)),
                          SizedBox(height: 20),
                          CircularProgressIndicator(value: progress, color: Colors.cyanAccent),
                          SizedBox(height: 20),
                          Text(status, style: TextStyle(color: Colors.white70, letterSpacing: 1.2)),
                        ],
                      )
                    : Icon(Icons.auto_awesome, size: 100, color: Colors.cyanAccent),
                ),
              ),

              // --- CHAT BOX (HIGHER & STYLISH) ---
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 50), // 50px bottom padding prevents button overlap
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Type a prompt...",
                      hintStyle: TextStyle(color: Colors.white24),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.rocket_launch, color: Colors.cyanAccent),
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
