import 'dart:convert';
import 'package:http/http.dart' as http;

class UnsplashService {
  static const String _accessKey = 'ctSPFv5UxM1TApVnIy5D9M_Tw59b5N_GUY2TZfAGqes';
  static const String _baseUrl = 'https://api.unsplash.com';

  // Fetch a single image URL based on a query (e.g., "hotel riyadh")
  Future<String?> fetchImageUrl(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/photos?query=$query&per_page=1'),
        headers: {
          'Authorization': 'Client-ID $_accessKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          return results[0]['urls']['regular'] as String;
        } else {
          print('No images found for query: $query');
          return null;
        }
      } else {
        print('Failed to fetch image from Unsplash: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching image from Unsplash: $e');
      return null;
    }
  }
}