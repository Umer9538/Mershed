import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isHumanSupportRequested = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        'sender': 'bot',
        'message': 'Hello! I’m your travel assistant. How can I help you today?',
      });
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': message});
      _isLoading = true;
      _messages.add({'sender': 'bot', 'message': 'Bot is typing...'});
    });

    try {
      final cachedResponse = await _getCachedResponse(message);
      if (cachedResponse != null) {
        setState(() {
          _messages.removeLast();
          _messages.add({'sender': 'bot', 'message': cachedResponse});
        });
      } else {
        final response = await _getBotResponse(message);
        setState(() {
          _messages.removeLast();
          _messages.add({'sender': 'bot', 'message': response});
        });
      }
    } catch (e) {
      final fallbackResponse = _getFallbackResponse(message);
      setState(() {
        _messages.removeLast();
        _messages.add({'sender': 'bot', 'message': fallbackResponse});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _messageController.clear();
    }
  }

  Future<String?> _getCachedResponse(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedResponse = prefs.getString('response_$message');
    if (cachedResponse != null) {
      print('Cache hit for message: $message, Response: $cachedResponse');
    }
    return cachedResponse;
  }

  Future<void> _cacheResponse(String message, String response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('response_$message', response);
    print('Cached response for message: $message');
  }

  Future<String> _getBotResponse(String message) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please check your network.')),
      );
      throw Exception('No internet connection');
    }

    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'You are a travel assistant. Provide helpful and accurate travel advice. $message'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 200,
      },
    });

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http.post(Uri.parse(url), headers: headers, body: body).timeout(Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final botResponse = data['candidates'][0]['content']['parts'][0]['text'] ?? 'I’m not sure how to respond to that.';
          await _cacheResponse(message, botResponse);
          return botResponse;
        } else if (response.statusCode == 429) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rate limit exceeded. Please wait and try again.')),
          );
          throw Exception('Rate limit exceeded');
        } else {
          print('Gemini API Error: Status Code ${response.statusCode}, Response: ${response.body}');
          throw Exception('Failed to get response: ${response.statusCode}');
        }
      } catch (e) {
        if (e is TimeoutException && attempt < 2) {
          await Future.delayed(Duration(seconds: 5));
          continue;
        }
        print('Gemini API Error: $e');
        throw e;
      }
    }
    throw Exception('Failed to get response after retries');
  }

  String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('hotel') && lowerMessage.contains('jeddah')) {
      return 'I can suggest some hotels! For example, in Jeddah, you might like the Ritz-Carlton or Hilton Jeddah for a family stay.';
    } else if (lowerMessage.contains('hotel') && lowerMessage.contains('riyadh')) {
      return 'In Riyadh, you might enjoy staying at the Four Seasons or Kingdom Centre Tower Hotel.';
    } else if (lowerMessage.contains('hotel') && lowerMessage.contains('mecca')) {
      return 'In Mecca, you can try the Fairmont Makkah Clock Royal Tower or the Pullman ZamZam Makkah for a comfortable stay.';
    } else if (lowerMessage.contains('transport') && lowerMessage.contains('mecca')) {
      return 'For transport in Mecca, you can use the Haramain High-Speed Railway to travel to Medina, or take a SAPTCO bus.';
    } else if (lowerMessage.contains('transport') && lowerMessage.contains('riyadh')) {
      return 'In Riyadh, you can use the Riyadh Metro. For example, travel from King Saud University to Kingdom Centre Tower on Line 1.';
    } else if (lowerMessage.contains('budget') && lowerMessage.contains('trip')) {
      return 'For a budget trip, consider staying in hostels or budget hotels, and use public transport like buses or the metro to save money.';
    } else if (lowerMessage.contains('places') && lowerMessage.contains('visit')) {
      return 'In Saudi Arabia, you can visit Al Masjid Al Haram in Mecca, Al Masjid an-Nabawi in Medina, or the Kingdom Centre Tower in Riyadh.';
    } else if (lowerMessage.contains('weather') && lowerMessage.contains('jeddah')) {
      return 'Jeddah is usually warm and humid. Expect temperatures around 25-35°C year-round, with higher humidity near the coast.';
    }
    return 'I’m having trouble connecting to my knowledge base. Please try again or request human support!';
  }

  Future<void> _requestHumanSupport() async {
    setState(() {
      _isHumanSupportRequested = true;
      _messages.add({
        'sender': 'bot',
        'message': 'I’ve requested human support for you. Someone will assist you soon!',
      });
    });

    try {
      await FirebaseFirestore.instance.collection('support_requests').add({
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'chat_history': _messages,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting human support: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Chatbot'),
        actions: [
          if (!_isHumanSupportRequested)
            IconButton(
              icon: const Icon(Icons.support_agent),
              onPressed: _isLoading ? null : _requestHumanSupport,
              tooltip: 'Request Human Support',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isBot = message['sender'] == 'bot';
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.grey[200] : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message['message']!,
                      style: TextStyle(
                        color: isBot ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about travel...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    onSubmitted: _isLoading || _isHumanSupportRequested ? null : _sendMessage,
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: _isLoading || _isHumanSupportRequested
                      ? null
                      : () => _sendMessage(_messageController.text),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}