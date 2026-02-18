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
  String status = "🌙 Moon Base Connecting...";
  String debugLog = "System: Initializing...";
  double progress = 0.0;
  bool isReady = false;

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

      if (await file.exists()) {
        setState(() { isReady = true; status = "LuneGPT Online"; });
        return;
      }

      const url = "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q2_K.gguf";
      log("📡 Pinging HuggingFace...");
      
      final dio = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 5,
        connectTimeout: Duration(seconds: 30),
      ));

      await dio.download(url, file.path, onReceiveProgress: (count, total) {
        if (total != -1) {
          setState(() {
            progress = count / total;
            status = "Syncing Neural Data: ${(progress * 100).toStringAsFixed(1)}%";
          });
        }
      });

      setState(() { isReady = true; status = "LuneGPT Online"; });
    } catch (e) {
      log("❌ CRITICAL: $e");
      setState(() => status = "Connection Failed. Try again.");
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
              // System Console for Logs
              Container(
                height: 80,
                width: double.infinity,
                margin: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  padding: EdgeInsets.all(10),
                  child: Text(debugLog, style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace')),
                ),
              ),

              // This is the part that caused the build error
              Expanded(
                child: Center(
                  child: !isReady 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nights_stay, size: 100, color: Colors.cyanAccent),
                          SizedBox(height: 40),
                          Container(
                            width: 250,
                            height: 6,
                            child: LinearProgressIndicator(
                              value: progress, 
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                            ),
                          ),
                          SizedBox(height: 25),
                          Text(status, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w300)),
                        ],
                      )
                    : Icon(Icons.bolt, size: 120, color: Colors.cyanAccent),
                ),
              ),

              // Chat Input Box (Lifted 60px to avoid system buttons)
              Padding(
                padding: EdgeInsets.fromLTRB(25, 0, 25, 60), 
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 10)
                    ],
                  ),
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter command...",
                      hintStyle: TextStyle(color: Colors.white24),
                      contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.send_rounded, color: Colors.cyanAccent),
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
