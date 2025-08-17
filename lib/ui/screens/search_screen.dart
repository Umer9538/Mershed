import 'package:flutter/material.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/models/hotel.dart';
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
      print('Searching with category: $_selectedCategory and query: $_searchQuery');
      List<Future<List<Map<String, dynamic>>>> searchFutures = [];

      if (_selectedCategory == 'All' || _selectedCategory == 'Destinations') {
        print('Adding Destinations search for query: $_searchQuery');
        searchFutures.add(_searchDestinations());
      }
      if (_selectedCategory == 'All' || _selectedCategory == 'Hotels') {
        print('Adding Hotels search for query: $_searchQuery');
        searchFutures.add(_searchHotels());
      }
      if (_selectedCategory == 'All' || _selectedCategory == 'Activities') {
        print('Adding Activities search for query: $_searchQuery');
        searchFutures.add(_searchActivities());
      }
      if (_selectedCategory == 'All' || _selectedCategory == 'Restaurants') {
        print('Adding Restaurants search for query: $_searchQuery');
        searchFutures.add(_searchRestaurants());
      }

      print('Executing ${searchFutures.length} search futures');
      List<List<Map<String, dynamic>>> results = await Future.wait(searchFutures);
      final combinedResults = results.expand((result) => result).toList();
      print('Combined Search Results: $combinedResults');

      setState(() {
        _searchResults = combinedResults;
      });
    } catch (e) {
      print('Error in _search: $e');
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
    try {
      final destinations = await BookingService().getDestinations(_searchQuery);
      final mappedDestinations = destinations.map((dest) {
        return {
          'type': 'destination',
          'id': dest['id'],
          'name': dest['name'],
          'location': dest['location'],
          'rating': dest['rating']?.toDouble() ?? 0.0,
          'photos': dest['photos'],
          'description': dest['description'],
          'destinationObject': dest,
        };
      }).toList();
      print('Mapped Destinations: $mappedDestinations');
      return mappedDestinations;
    } catch (e) {
      print('Error in _searchDestinations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchHotels() async {
    try {
      final hotels = await BookingService().getHotels(
        _searchQuery,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
      );
      final mappedHotels = hotels.map((hotel) {
        return {
          'type': 'hotel',
          'id': hotel.id,
          'name': hotel.name,
          'location': hotel.location,
          'pricePerNight': hotel.pricePerNight,
          'rating': 4.5,
          'isAvailable': true,
          'photos': hotel.photos,
          'reviews': hotel.reviews,
          'hotelObject': hotel,
        };
      }).toList();
      print('Mapped Hotels: $mappedHotels');
      return mappedHotels;
    } catch (e) {
      print('Error fetching hotels: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchActivities() async {
    try {
      final activities = await BookingService().getActivities(_searchQuery);
      final mappedActivities = activities.map((activity) {
        return {
          'type': 'activity',
          'id': activity['id'],
          'name': activity['name'],
          'location': activity['location'],
          'price': activity['price']?.toDouble() ?? 0.0,
          'isAvailable': true,
          'photos': activity['photos'],
          'description': activity['description'],
          'activityObject': activity,
        };
      }).toList();
      print('Mapped Activities: $mappedActivities');
      return mappedActivities;
    } catch (e) {
      print('Error fetching activities: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchRestaurants() async {
    try {
      final restaurants = await BookingService().getRestaurants(_searchQuery);
      final mappedRestaurants = restaurants.map((restaurant) {
        return {
          'type': 'restaurant',
          'id': restaurant['id'],
          'name': restaurant['name'],
          'location': restaurant['location'],
          'price': restaurant['price']?.toDouble() ?? 0.0,
          'rating': 4.0,
          'isAvailable': true,
          'photos': restaurant['photos'],
          'description': restaurant['description'],
          'restaurantObject': restaurant,
        };
      }).toList();
      print('Mapped Restaurants: $mappedRestaurants');
      return mappedRestaurants;
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  void _navigateToDetail(Map<String, dynamic> result) {
    print('Navigating to detail for: ${result['type']} - ${result['name']}');
    switch (result['type']) {
      case 'destination':
      // Navigation for destinations is disabled; do nothing
        break;
      case 'hotel':
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
        Navigator.pushNamed(
          context,
          AppRoutes.booking,
          arguments: {
            'item': result['activityObject'],
            'type': 'activities',
            'checkInDate': _checkInDate,
            'guests': 1,
          },
        );
        break;
      case 'restaurant':
        Navigator.pushNamed(
          context,
          AppRoutes.booking,
          arguments: {
            'item': result['restaurantObject'],
            'type': 'restaurants',
            'checkInDate': _checkInDate,
            'guests': 1,
          },
        );
        break;
    }
  }

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
        }
        return SizedBox(
          height: height,
          width: width ?? double.infinity,
          child: Image.network(
            snapshot.hasData && snapshot.data != null
                ? snapshot.data!
                : 'https://via.placeholder.com/300x200?text=${query.replaceAll(' ', '+')}',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.error, color: Colors.red, size: 50)),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );
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

  Widget _buildResultCard(Map<String, dynamic> result) {
    final theme = Theme.of(context);
    final isHotel = result['type'] == 'hotel';
    final price = isHotel
        ? (result['hotelObject'] as Hotel).pricePerNight *
        _checkOutDate.difference(_checkInDate).inDays
        : result['price']?.toDouble();

    print('Building card for: ${result['type']} - ${result['name']}');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          result['photos'] != null && result['photos'].isNotEmpty
              ? SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.network(
              result['photos'][0],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildUnsplashImage('${result['type']} ${result['location'].toLowerCase()}'),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          )
              : _buildUnsplashImage('${result['type']} ${result['location'].toLowerCase()}'),
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
                        result['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (result['rating'] != null)
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
                    Text(result['location'], style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                if (result['description'] != null || (isHotel && result['reviews']?.isNotEmpty == true)) ...[
                  const SizedBox(height: 8),
                  Text(
                    result['description'] ?? (isHotel ? '"${result['reviews'][0]}"' : ''),
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
                if (isHotel) ...[
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
                ],
                const SizedBox(height: 16),
                if (isHotel) const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (price != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isHotel)
                            Text(
                                'Total for ${_checkOutDate.difference(_checkInDate).inDays} nights',
                                style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(
                            '${price.toStringAsFixed(0)} SAR',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    if (result['type'] != 'destination') // Only show button for non-destinations
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => _navigateToDetail(result),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'BOOK NOW',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: const Color(0xFF40557b),
      ),
      body: Column(
        children: [
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
              itemBuilder: (context, index) => _buildResultCard(_searchResults[index]),
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
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
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