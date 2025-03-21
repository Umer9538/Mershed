import 'package:flutter/material.dart';
import 'package:mershed/core/models/hotel.dart';
import 'package:mershed/core/models/restaurant.dart';
import 'package:mershed/core/models/activity.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/services/booking_service.dart';
import 'package:mershed/core/services/unsplash_service.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:mershed/core/booking_category.dart';
import 'package:provider/provider.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _destinationController = TextEditingController();
  final _searchFocusNode = FocusNode();
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 2));
  int _guests = 2;
  BookingCategory _category = BookingCategory.hotels;
  List<dynamic> _items = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadFeaturedItems();
  }

  Future<void> _loadFeaturedItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _fetchItems('RUH', _category); // Default to Riyadh
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Could not load featured items: $e');
    }
  }

  Future<List<dynamic>> _fetchItems(String destination, BookingCategory category) async {
    try {
      if (category == BookingCategory.hotels) {
        return await BookingService().getHotels(
          destination,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
        );
      } else if (category == BookingCategory.restaurants) {
        return await BookingService().getRestaurants(destination);
      } else {
        return await BookingService().getActivities(destination);
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching items: $e');
      return [];
    }
  }

  Future<void> _searchItems() async {
    if (_destinationController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a destination');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final items = await _fetchItems(_destinationController.text, _category);
      setState(() {
        _items = items;
        _isLoading = false;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error searching items: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGuestPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in required'),
        content: const Text('Please sign in to book and enjoy exclusive member benefits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('SIGN IN'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkInDate : _checkOutDate,
      firstDate: isCheckIn ? DateTime.now() : _checkInDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate.isBefore(_checkInDate) || _checkOutDate.isAtSameMomentAs(_checkInDate)) {
            _checkOutDate = _checkInDate.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _bookItem(dynamic item) async {
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showGuestPrompt();
      return;
    }

    try {
      final nights = _checkOutDate.difference(_checkInDate).inDays;
      final totalPrice = (item is Hotel)
          ? item.pricePerNight * nights
          : (item is Restaurant)
          ? item.averageCostPerPerson * _guests
          : (item is Activity)
          ? item.cost
          : 0.0;

      final success = await BookingService().bookItem(
        item.id,
        authProvider.user!.id,
        type: _category,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        guests: _guests,
        totalPrice: totalPrice,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully booked ${item.name}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error booking item: $e');
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
          // Fallback to placeholder image if Unsplash fails
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Book Your Experience',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildUnsplashImage('saudi arabia hotel', height: 200),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (authProvider.isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
                  tooltip: 'My Profile',
                )
              else
                TextButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Sign In', style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<BookingCategory>(
                      value: _category,
                      onChanged: (BookingCategory? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _category = newValue;
                            _items.clear();
                            _hasSearched = false;
                            _loadFeaturedItems();
                          });
                        }
                      },
                      items: BookingCategory.values
                          .map((category) => DropdownMenuItem<BookingCategory>(
                        value: category,
                        child: Text(category.toString().split('.').last),
                      ))
                          .toList(),
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: TextStyle(color: theme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _destinationController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Where would you like to go? (e.g., RUH, JED, MKK)',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Check-in',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('EEE, MMM d').format(_checkInDate),
                                      style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Check-out',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('EEE, MMM d').format(_checkOutDate),
                                      style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Guests',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('$_guests ${_guests == 1 ? 'Guest' : 'Guests'}',
                                  style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                                color: theme.primaryColor,
                              ),
                              Text('$_guests',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _guests < 10 ? () => setState(() => _guests++) : null,
                                color: theme.primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _searchItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          'SEARCH ${_category.toString().split('.').last.toUpperCase()}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hasSearched
                        ? 'Results for "${_destinationController.text}"'
                        : 'Featured ${_category.toString().split('.').last}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_items.isNotEmpty)
                    Text(
                      '${_items.length} ${_items.length == 1 ? _category.toString().split('.').last : _category.toString().split('.').last + 's'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
          _isLoading && _items.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                      'Searching for the best ${_category.toString().split('.').last.toLowerCase()}...',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          )
              : _items.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _category == BookingCategory.hotels
                        ? Icons.hotel_outlined
                        : _category == BookingCategory.restaurants
                        ? Icons.restaurant
                        : Icons.local_activity,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _hasSearched
                        ? 'No ${_category.toString().split('.').last.toLowerCase()} found for "${_destinationController.text}"'
                        : 'No featured ${_category.toString().split('.').last.toLowerCase()} available',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  if (_hasSearched)
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try a different search'),
                      onPressed: () {
                        _destinationController.clear();
                        setState(() {
                          _hasSearched = false;
                          _loadFeaturedItems();
                        });
                      },
                    ),
                ],
              ),
            ),
          )
              : SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = _items[index];
                  final nights = _checkOutDate.difference(_checkInDate).inDays;
                  final totalPrice = (item is Hotel)
                      ? item.pricePerNight * nights
                      : (item is Restaurant)
                      ? item.averageCostPerPerson * _guests
                      : (item is Activity)
                      ? item.cost
                      : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUnsplashImage('hotel ${item.location.toLowerCase()}'),
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
                                      item.name,
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      const Text('4.5',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(item.location,
                                      style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
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
                                      onPressed: () => _bookItem(item),
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
                },
                childCount: _items.length,
              ),
            ),
          ),
        ],
      ),
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
  void dispose() {
    _destinationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
















/*
import 'package:flutter/material.dart';
import 'package:mershed/core/models/hotel.dart';
import 'package:mershed/core/models/restaurant.dart';
import 'package:mershed/core/models/activity.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/services/booking_service.dart';
import 'package:mershed/ui/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:mershed/core/booking_category.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _destinationController = TextEditingController();
  final _searchFocusNode = FocusNode();
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 2));
  int _guests = 2;
  BookingCategory _category = BookingCategory.hotels;
  List<dynamic> _items = []; // Can hold Hotels, Restaurants, or Activities
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadFeaturedItems();
  }

  Future<void> _loadFeaturedItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _fetchItems('Featured', _category); // 'Featured' will use 'NYC' as fallback
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Could not load featured items: $e');
    }
  }

  Future<List<dynamic>> _fetchItems(String destination, BookingCategory category) async {
    try {
      if (category == BookingCategory.hotels) {
        return await BookingService().getHotels(destination);
      } else if (category == BookingCategory.restaurants) {
        return await BookingService().getRestaurants(destination);
      } else {
        return await BookingService().getActivities(destination);
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching items: $e');
      return [];
    }
  }

  Future<void> _searchItems() async {
    if (_destinationController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a destination');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final items = await _fetchItems(_destinationController.text, _category);
      setState(() {
        _items = items;
        _isLoading = false;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error searching items: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGuestPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in required'),
        content: const Text('Please sign in to book and enjoy exclusive member benefits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('SIGN IN'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkInDate : _checkOutDate,
      firstDate: isCheckIn ? DateTime.now() : _checkInDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate.isBefore(_checkInDate) || _checkOutDate.isAtSameMomentAs(_checkInDate)) {
            _checkOutDate = _checkInDate.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _bookItem(dynamic item) async {
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showGuestPrompt();
      return;
    }

    try {
      final nights = _checkOutDate.difference(_checkInDate).inDays;
      final totalPrice = (item is Hotel)
          ? item.pricePerNight * nights
          : (item is Restaurant)
          ? item.averageCostPerPerson * _guests
          : (item is Activity) ? item.cost : 0.0;

      final success = await BookingService().bookItem(
        item.id,
        authProvider.user!.id,
        type: _category,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        guests: _guests,
        totalPrice: totalPrice,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully booked ${item.name}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error booking item: $e');
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final success = await BookingService().cancelBooking(bookingId);
      if (success) {
        _showErrorSnackBar('Booking cancelled successfully');
        _loadFeaturedItems(); // Refresh the list
      }
    } catch (e) {
      _showErrorSnackBar('Error cancelling booking: $e');
    }
  }

  Future<void> _modifyBooking(String bookingId) async {
    // Placeholder for modify logic - to be implemented with API
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modify Booking'),
        content: const Text('Modification feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Book Your Experience',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (authProvider.isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    // Navigate to profile screen
                  },
                  tooltip: 'My Profile',
                )
              else
                TextButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Sign In',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection
                    DropdownButton<BookingCategory>(
                      value: _category,
                      onChanged: (BookingCategory? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _category = newValue;
                            _items.clear();
                            _hasSearched = false;
                            _loadFeaturedItems();
                          });
                        }
                      },
                      items: BookingCategory.values.map((BookingCategory category) {
                        return DropdownMenuItem<BookingCategory>(
                          value: category,
                          child: Text(category.toString().split('.').last),
                        );
                      }).toList(),
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: TextStyle(color: theme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    // Destination Field
                    TextField(
                      controller: _destinationController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Where would you like to go?',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Selection Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-in',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEE, MMM d').format(_checkInDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-out',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEE, MMM d').format(_checkOutDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Guests Selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guests',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_guests ${_guests == 1 ? 'Guest' : 'Guests'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _guests > 1
                                    ? () => setState(() => _guests--)
                                    : null,
                                color: Theme.of(context).primaryColor,
                              ),
                              Text(
                                '$_guests',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _guests < 10
                                    ? () => setState(() => _guests++)
                                    : null,
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _searchItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'SEARCH ${_category.toString().split('.').last.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hasSearched
                        ? 'Results for "${_destinationController.text}"'
                        : 'Featured ${_category.toString().split('.').last}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_items.isNotEmpty)
                    Text(
                      '${_items.length} ${_items.length == 1 ? _category.toString().split('.').last : _category.toString().split('.').last + 's'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ),
          _isLoading && _items.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Searching for the best ${_category.toString().split('.').last.toLowerCase()}...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
              : _items.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _category == BookingCategory.hotels
                        ? Icons.hotel_outlined
                        : _category == BookingCategory.restaurants
                        ? Icons.restaurant
                        : Icons.local_activity,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _hasSearched
                        ? 'No ${_category.toString().split('.').last.toLowerCase()} found for "${_destinationController.text}"'
                        : 'No featured ${_category.toString().split('.').last.toLowerCase()} available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_hasSearched)
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try a different search'),
                      onPressed: () {
                        _destinationController.clear();
                        setState(() {
                          _hasSearched = false;
                          _loadFeaturedItems();
                        });
                      },
                    ),
                ],
              ),
            ),
          )
              : SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = _items[index];
                  final nights = _checkOutDate.difference(_checkInDate).inDays;
                  final totalPrice = (item is Hotel)
                      ? item.pricePerNight * nights
                      : (item is Restaurant)
                      ? item.averageCostPerPerson * _guests
                      : (item is Activity) ? item.cost : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            image: DecorationImage(
                              image: NetworkImage(
                                _category == BookingCategory.hotels
                                    ? 'https://source.unsplash.com/featured/?hotel,${item.location}'
                                    : _category == BookingCategory.restaurants
                                    ? 'https://source.unsplash.com/featured/?restaurant'
                                    : 'https://source.unsplash.com/featured/?activity',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _category == BookingCategory.hotels
                                        ? '${item.pricePerNight.toStringAsFixed(0)} SAR/night'
                                        : _category == BookingCategory.restaurants
                                        ? '${item.averageCostPerPerson.toStringAsFixed(0)} SAR/person'
                                        : '${item.cost.toStringAsFixed(0)} SAR',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '4.5', // Mock rating
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.location,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
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
                                      Text(
                                        _category == BookingCategory.hotels
                                            ? 'Total for $nights nights'
                                            : _category == BookingCategory.restaurants
                                            ? 'Total for $_guests guests'
                                            : 'Total cost',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${totalPrice.toStringAsFixed(0)} SAR',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (item.bookingId != null) // Check if already booked
                                        IconButton(
                                          icon: const Icon(Icons.cancel),
                                          onPressed: () => _cancelBooking(item.bookingId!),
                                          color: Colors.red,
                                          tooltip: 'Cancel Booking',
                                        ),
                                      SizedBox(
                                        height: 44,
                                        child: ElevatedButton(
                                          onPressed: () => _bookItem(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            item.bookingId != null ? 'MODIFY' : 'BOOK NOW',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: _items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[700],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}*/
