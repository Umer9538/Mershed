import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/models/hotel.dart';
import 'package:mershed/core/models/activity.dart';
import 'package:mershed/core/models/restaurant.dart';
import 'package:mershed/core/services/booking_service.dart';
import 'package:mershed/core/services/unsplash_service.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All'; // Filter by category
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 8));
  int _guests = 2;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
        _search();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      // Search across all categories
      List<Future<List<Map<String, dynamic>>>> searchFutures = [];

      if (_selectedCategory == 'All' || _selectedCategory == 'Destinations') {
        searchFutures.add(_searchDestinations());
      }
      if (_selectedCategory == 'All' || _selectedCategory == 'Hotels') {
        searchFutures.add(_searchHotels());
      }
      if (_selectedCategory == 'All' || _selectedCategory == 'Activities') {
        searchFutures.add(_searchActivities());
      }
      if (_selectedCategory == 'All' || _selectedCategory == 'Restaurants') {
        searchFutures.add(_searchRestaurants());
      }

      // Wait for all searches to complete
      List<List<Map<String, dynamic>>> results = await Future.wait(searchFutures);

      // Combine results
      setState(() {
        _searchResults = results.expand((result) => result).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _searchDestinations() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('destinations')
        .where('name', isGreaterThanOrEqualTo: _searchQuery)
        .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'type': 'destination',
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'location': data['location'] ?? 'Unknown',
        'rating': data['rating']?.toDouble() ?? 0.0,
        'imageUrl': data['imageUrl'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _searchHotels() async {
    try {
      final hotels = await BookingService().getHotels(
        _searchQuery,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
      );

      return hotels.map((hotel) {
        return {
          'type': 'hotel',
          'id': hotel.id,
          'name': hotel.name,
          'location': hotel.location,
          'pricePerNight': hotel.pricePerNight,
          'rating': 4.5, // Hardcoded for now, as Rapid API response doesn't provide rating
          'isAvailable': true, // Assume available for now
          'photos': hotel.photos,
          'reviews': hotel.reviews,
          'hotelObject': hotel, // Store the full hotel object for navigation
        };
      }).toList();
    } catch (e) {
      print('Error fetching hotels from Rapid API: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchActivities() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('name', isGreaterThanOrEqualTo: _searchQuery)
        .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'type': 'activity',
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'location': data['location'] ?? 'Unknown',
        'price': data['price']?.toDouble() ?? 0.0,
        'isAvailable': data['isAvailable'] ?? false,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _searchRestaurants() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('name', isGreaterThanOrEqualTo: _searchQuery)
        .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'type': 'restaurant',
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'location': data['location'] ?? 'Unknown',
        'price': data['price']?.toDouble() ?? 0.0,
        'rating': data['rating']?.toDouble() ?? 0.0,
        'isAvailable': data['isAvailable'] ?? false,
      };
    }).toList();
  }

  void _navigateToDetail(Map<String, dynamic> result) {
    switch (result['type']) {
      case 'destination':
        Navigator.pushNamed(
          context,
          AppRoutes.destinationDetail,
          arguments: result['id'],
        );
        break;
      case 'hotel':
      // Navigate to BookingScreen with the hotel object
        Navigator.pushNamed(
          context,
          AppRoutes.booking,
          arguments: {
            'hotel': result['hotelObject'],
            'checkInDate': _checkInDate,
            'checkOutDate': _checkOutDate,
            'guests': _guests,
          },
        );
        break;
      case 'activity':
      case 'restaurant':
        Navigator.pushNamed(
          context,
          AppRoutes.booking,
          arguments: result['id'],
        );
        break;
    }
  }

  // Custom widget to load images from Unsplash with fallback
  Widget _buildUnsplashImage(String query, {double height = 180, double? width}) {
    return FutureBuilder<String?>(
      future: UnsplashService().fetchImageUrl(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            width: width ?? double.infinity,
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return SizedBox(
            height: height,
            width: width ?? double.infinity,
            child: Image.network(
              'https://via.placeholder.com/300x200?text=${query.replaceAll(' ', '+')}+Hotel',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          );
        } else {
          return SizedBox(
            height: height,
            width: width ?? double.infinity,
            child: Image.network(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildAmenityItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: const Color(0xFFB94A2F),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search destinations, hotels, activities...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          // Category Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All'),
                  _buildCategoryChip('Destinations'),
                  _buildCategoryChip('Hotels'),
                  _buildCategoryChip('Activities'),
                  _buildCategoryChip('Restaurants'),
                ],
              ),
            ),
          ),
          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
              child: Text(
                _searchQuery.isEmpty ? 'Start typing to search...' : 'No results found',
                style: const TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                if (result['type'] == 'hotel') {
                  // Display hotel results in a style similar to BookingScreen
                  final hotel = result['hotelObject'] as Hotel;
                  final nights = _checkOutDate.difference(_checkInDate).inDays;
                  final totalPrice = hotel.pricePerNight * nights;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        hotel.photos != null && hotel.photos!.isNotEmpty
                            ? SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: Image.network(
                            hotel.photos![0],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildUnsplashImage(
                                    'hotel ${hotel.location.toLowerCase()}'),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                          ),
                        )
                            : _buildUnsplashImage('hotel ${hotel.location.toLowerCase()}'),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      hotel.name,
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        result['rating'].toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(hotel.location,
                                      style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                              if (hotel.reviews != null && hotel.reviews!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '"${hotel.reviews![0]}"',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontStyle: FontStyle.italic),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildAmenityItem(Icons.wifi, 'Free WiFi'),
                                  _buildAmenityItem(Icons.pool, 'Pool'),
                                  _buildAmenityItem(Icons.restaurant, 'Restaurant'),
                                  _buildAmenityItem(Icons.local_parking, 'Parking'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total for $nights nights',
                                          style: TextStyle(color: Colors.grey[600])),
                                      const SizedBox(height: 4),
                                      Text('${totalPrice.toStringAsFixed(0)} SAR',
                                          style: const TextStyle(
                                              fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () => _navigateToDetail(result),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('BOOK NOW',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Display other results (destinations, activities, restaurants) as before
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        result['type'] == 'destination'
                            ? Icons.location_on
                            : result['type'] == 'activity'
                            ? Icons.event
                            : Icons.restaurant,
                        color: const Color(0xFFB94A2F),
                      ),
                      title: Text(result['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result['location']),
                          if (result['rating'] != null)
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(result['rating'].toString()),
                              ],
                            ),
                          if (result['price'] != null)
                            Text('Price: ${result['price']} SAR'),
                          if (result['isAvailable'] != null)
                            Text(
                              result['isAvailable'] ? 'Available' : 'Not Available',
                              style: TextStyle(
                                color: result['isAvailable'] ? Colors.green : Colors.red,
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _navigateToDetail(result),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    bool isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        selectedColor: const Color(0xFFB94A2F),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = category;
              _search();
            });
          }
        },
      ),
    );
  }
}