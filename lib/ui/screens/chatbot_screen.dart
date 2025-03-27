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
        'message': 'Welcome to TravelGenie! I am your AI travel companion. What destination or travel advice can I help you with today?',
      });
    });
  }

  // New method to handle fallback responses
  String _getFallbackResponse(String message) {
    final List<String> fallbackResponses = [
      'I apologize, but I am having trouble processing your request. Could you please rephrase that?',
      'Hmm, my connection seems a bit spotty. Would you mind repeating your question?',
      'It looks like there might be a temporary issue with my system. Let me suggest requesting human support if this persists.',
    ];

    // Pseudo-random selection of fallback response
    return fallbackResponses[message.length % fallbackResponses.length];
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': message});
      _isLoading = true;
      _messages.add({'sender': 'bot', 'message': 'Generating response...'});
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
      _focusNode.requestFocus();
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

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    print('Loaded GEMINI_API_KEY: $apiKey'); // Debug
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in the .env file');
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'You are a travel assistant. Provide travel advice without using markdown or asterisks. Format the response cleanly. $message'}
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
          final botResponse = data['candidates'][0]['content']['parts'][0]['text'] ?? 'I am not sure how to respond to that.';
          await _cacheResponse(message, botResponse);
          return botResponse;
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

  Future<void> _requestHumanSupport() async {
    setState(() {
      _isHumanSupportRequested = true;
      _messages.add({
        'sender': 'bot',
        'message': 'I have requested human support for you. Someone will assist you soon!',
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

        title: Row(
          children: [
            Icon(Icons.flight_takeoff, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('TravelGenie', style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            )),
          ],
        ),
        actions: [
          if (!_isHumanSupportRequested)
            Tooltip(
              message: 'Need extra help? Connect with a human agent',
              child: IconButton(
                icon: Icon(Icons.support_agent, color: theme.colorScheme.primary),
                onPressed: _isLoading ? null : _requestHumanSupport,
              ),
            ),
        ],
        backgroundColor: Color(0xFFB94A2F),
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
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
                        color: isBot
                            ? theme.colorScheme.secondaryContainer
                            : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message['message']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isBot ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onPrimaryContainer,
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
                        hintText: 'Ask me anything about your next adventure...',
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      onSubmitted: _isLoading || _isHumanSupportRequested ? null : _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: _isLoading || _isHumanSupportRequested
                          ? theme.colorScheme.secondary.withOpacity(0.5)
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Icon(Icons.send, color: theme.colorScheme.onPrimary),
                      onPressed: _isLoading || _isHumanSupportRequested
                          ? null
                          : () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}