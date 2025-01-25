import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class PertanyaanPage extends StatefulWidget {
  @override
  _PertanyaanPageState createState() => _PertanyaanPageState();
}

class _PertanyaanPageState extends State<PertanyaanPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = []; // Untuk menyimpan pesan dan respons
  final String _cacheKey = 'chat_history'; // Key untuk menyimpan riwayat pesan

  @override
  void initState() {
    super.initState();
    _loadChatHistory(); // Memuat riwayat pesan saat halaman dibuka
  }

  // Fungsi untuk memuat riwayat pesan dari cache
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);

    if (cachedData != null) {
      final List<dynamic> decodedData = json.decode(cachedData);
      setState(() {
        _messages = List<Map<String, String>>.from(
          decodedData.map((item) => Map<String, String>.from(item)),
        );
      });
    }
  }

  // Fungsi untuk menyimpan riwayat pesan ke cache
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedData = json.encode(_messages);
    prefs.setString(_cacheKey, encodedData);
  }

  // Fungsi untuk mengirim pesan ke backend
  Future<void> _sendMessage(String message) async {
    final url = Uri.parse("http://192.168.1.6:8000/chat"); // Ubah sesuai IP server
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data["response"];

        // Update UI dengan pesan dan respons
        setState(() {
          _messages.add({"user": message, "bot": botResponse});
        });

        // Simpan riwayat pesan ke cache
        await _saveChatHistory();
      } else {
        throw Exception("Gagal mendapatkan respons dari server.");
      }
    } catch (error) {
      setState(() {
        _messages.add({"user": message, "bot": "Gagal terhubung ke server."});
      });

      // Simpan riwayat pesan ke cache meskipun gagal
      await _saveChatHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Warna latar belakang yang lembut
      body: Column(
        children: [
          // Header dengan gambar dan teks
          Container(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade800, // Warna biru gelap
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/bot.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 16),
                Text(
                  "Tanya Sam, Si Bot Pintar!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "Dapatkan informasi seputar bencana alam, tips keselamatan, dan saran darurat dari Sam, si bot pintar kami.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pesan pengguna
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          message["user"]!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    // Respons bot
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          message["bot"]!,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Input pesan
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ketik pertanyaan Anda...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      final message = _controller.text.trim();
                      if (message.isNotEmpty) {
                        _sendMessage(message);
                        _controller.clear();
                      }
                    },
                    icon: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}