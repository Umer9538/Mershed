import 'package:flutter/material.dart';
import 'package:mershed/core/models/recommendation.dart';
import 'package:mershed/core/services/ai_service.dart';

class RecommendationProvider with ChangeNotifier {
  final AiService _aiService = AiService();
  List<Recommendation> _recommendations = [];

  List<Recommendation> get recommendations => _recommendations;

  Future<void> fetchRecommendations(double budget, String destination) async {
    _recommendations = await _aiService.getRecommendations(budget, destination);
    notifyListeners();
  }
}