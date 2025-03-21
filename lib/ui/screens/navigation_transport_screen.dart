import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:mershed/core/services/map_service.dart';
import 'package:mershed/ui/screens/map_screen.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mershed/core/services/car_rental_service.dart';
import 'package:mershed/core/services/public_transport_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NavigationTransportScreen extends StatefulWidget {
  const NavigationTransportScreen({super.key});

  @override
  State<NavigationTransportScreen> createState() => _NavigationTransportScreenState();
}

class _NavigationTransportScreenState extends State<NavigationTransportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Color(0xFFB94A2F);
    final backgroundColor = Color(0xFFF7EFE4);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Navigation & Transportation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Map'),
            Tab(text: 'Public Transport'),
            Tab(text: 'Car Rental'),
            Tab(text: 'Permits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // FR9: Real-time navigation (already implemented)
          const MapScreen(),

          // FR10: Public transportation routes
          const PublicTransportScreen(),

          // FR11: Car rental and pickup locations
          const CarRentalScreen(),

          // FR12: Car rental permit guidance
          const PermitGuidanceScreen(),
        ],
      ),
    );
  }
}

// FR10: Public Transport Screen
class PublicTransportScreen extends StatefulWidget {
  const PublicTransportScreen({super.key});

  @override
  State<PublicTransportScreen> createState() => _PublicTransportScreenState();
}

class _PublicTransportScreenState extends State<PublicTransportScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  List<PublicTransportRoute> _routes = [];
  PublicTransportRoute? _selectedRoute;
  late flutter_map.MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = flutter_map.MapController();
  }

  Future<void> _searchRoutes() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both start and end locations')),
      );
      return;
    }

    try {
      final routes = await PublicTransportService().searchRoutes(
        _startController.text,
        _endController.text,
      );
      setState(() {
        _routes = routes;
        _selectedRoute = routes.isNotEmpty ? routes[0] : null;
        if (_selectedRoute != null) {
          _mapController.move(_selectedRoute!.polylinePoints[0], 12);
        }
      });
    } catch (e) {
      String errorMessage = 'Error fetching routes: $e';
      if (e.toString().contains('REQUEST_DENIED')) {
        errorMessage =
        'Failed to fetch routes. Please ensure the Geocoding and Directions APIs are enabled in Google Cloud Console and billing is set up.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _selectRoute(PublicTransportRoute route) {
    setState(() {
      _selectedRoute = route;
      _mapController.move(route.polylinePoints[0], 12);
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Input fields and search button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    labelText: 'End Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _searchRoutes,
                  child: const Text('Search Routes'),
                ),
              ],
            ),
          ),

          // Map to show the selected route
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3, // Responsive height
            child: flutter_map.FlutterMap(
              mapController: _mapController,
              options: flutter_map.MapOptions(
                center: latlong.LatLng(24.7136, 46.6753), // Default: Riyadh
                zoom: 10,
              ),
              children: [
                flutter_map.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Removed subdomains
                  userAgentPackageName: 'com.example.mershed',
                ),
                if (_selectedRoute != null)
                  flutter_map.PolylineLayer(
                    polylines: [
                      flutter_map.Polyline(
                        points: _selectedRoute!.polylinePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Routes list
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3, // Responsive height
            child: ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                return Card(
                  child: ListTile(
                    title: Text(route.summary),
                    subtitle: Text('Duration: ${route.duration}, Distance: ${route.distance}'),
                    onTap: () => _selectRoute(route),
                    selected: _selectedRoute == route,
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                  ),
                );
              },
            ),
          ),

          // Instructions for selected route
          if (_selectedRoute != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedRoute!.instructions
                      .asMap()
                      .entries
                      .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('${entry.key + 1}. ${entry.value}'),
                  ))
                      .toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// FR11: Car Rental Screen
class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  List<CarRentalLocation> _locations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCarRentalLocations();
  }

  Future<void> _loadCarRentalLocations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locations = await CarRentalService().getCarRentalLocations();
      if (mounted) {
        setState(() {
          _locations = locations;
          if (_locations.isEmpty) {
            _errorMessage = 'No car rental locations found for this area.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading car rental locations: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCarRentalLocations,
            child: const Text('Retry'),
          ),
        ],
      ),
    )
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _locations.length,
        itemBuilder: (context, index) {
          final location = _locations[index];
          return Card(
            child: ListTile(
              title: Text(location.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location.address),
                  const SizedBox(height: 4),
                  Text('Available Cars: ${location.availableCars}'),
                  Text('Price: ${location.pricePerDay} SAR/day'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.directions),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreenWithLocation(location: location.location),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper MapScreen to show specific location
class MapScreenWithLocation extends StatefulWidget {
  final latlong.LatLng location;

  const MapScreenWithLocation({super.key, required this.location});

  @override
  State<MapScreenWithLocation> createState() => _MapScreenWithLocationState();
}

class _MapScreenWithLocationState extends State<MapScreenWithLocation> {
  late flutter_map.MapController _mapController;
  Set<flutter_map.Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _mapController = flutter_map.MapController();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    setState(() {
      _markers = {
        flutter_map.Marker(
          point: widget.location,
          child: const Icon(
            Icons.car_rental,
            color: Colors.blue,
            size: 40,
          ),
        ),
      };
      _mapController.move(widget.location, 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Rental Location'),
      ),
      body: flutter_map.FlutterMap(
        mapController: _mapController,
        options: flutter_map.MapOptions(
          center: widget.location,
          zoom: 15,
        ),
        children: [
          flutter_map.TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Removed subdomains
            userAgentPackageName: 'com.example.mershed',
          ),
          flutter_map.MarkerLayer(markers: _markers.toList()),
        ],
      ),
    );
  }
}

// FR12: Permit Guidance Screen
// FR12: Permit Guidance Screen
class PermitGuidanceScreen extends StatefulWidget {
  const PermitGuidanceScreen({super.key});

  @override
  State<PermitGuidanceScreen> createState() => _PermitGuidanceScreenState();
}

class _PermitGuidanceScreenState extends State<PermitGuidanceScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  bool _isLoading = false;
  String? _requestStatus;
  String? _requestId; // To store the request ID for status checking

  Future<void> _submitPermitRequest() async {
    if (_idController.text.isEmpty || _vehicleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Validate National ID (assuming a 13-digit CNIC for Pakistan)
    if (_idController.text.length != 13 || !RegExp(r'^\d+$').hasMatch(_idController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('National ID must be a 13-digit number (e.g., CNIC)')),
      );
      return;
    }

    // Validate vehicle number plate (basic format check, e.g., ABC-123)
    if (!RegExp(r'^[A-Z]{3}-\d{3}$').hasMatch(_vehicleController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle number plate must be in the format ABC-123')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _requestStatus = null;
      _requestId = null;
    });

    try {
      final response = await AbsherNafathService().requestPermit(
        nationalId: _idController.text,
        vehicleDetails: _vehicleController.text,
      );
      if (mounted) {
        setState(() {
          _requestStatus = response['message'];
          _requestId = response['requestId'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkPermitStatus() async {
    if (_requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No permit request found. Please submit a request first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _requestStatus = null;
    });

    try {
      final statusResponse = await AbsherNafathService().checkPermitStatus(requestId: _requestId!);
      if (mounted) {
        setState(() {
          // Capitalize the approval status and display it
          String approvalStatus = statusResponse['approvalStatus'];
          approvalStatus = approvalStatus[0].toUpperCase() + approvalStatus.substring(1);
          _requestStatus = 'Permit Status: $approvalStatus';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking permit status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.black;
    if (status.contains('Approved')) return Colors.green;
    if (status.contains('Rejected')) return Colors.red;
    if (status.contains('Pending')) return Colors.orange;
    return Colors.black;
  }

  @override
  void dispose() {
    _idController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Car Rental Permit Guidance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Step 1: Enter your National ID (CNIC)'),
          const SizedBox(height: 8),
          const Text('Step 2: Provide vehicle details (e.g., number plate)'),
          const SizedBox(height: 8),
          const Text('Step 3: Submit the request'),
          const SizedBox(height: 8),
          const Text('Step 4: Check the approval status'),
          const SizedBox(height: 16),
          const Text(
            'Note: This is a simulated permit request for FYP purposes.',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: 'National ID (CNIC)',
              border: OutlineInputBorder(),
              hintText: 'e.g., 1234567890123',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _vehicleController,
            decoration: const InputDecoration(
              labelText: 'Vehicle Number Plate',
              border: OutlineInputBorder(),
              hintText: 'e.g., ABC-123',
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              ElevatedButton(
                onPressed: _submitPermitRequest,
                child: const Text('Submit Permit Request'),
              ),
              const SizedBox(height: 8),
              if (_requestId != null)
                ElevatedButton(
                  onPressed: _checkPermitStatus,
                  child: const Text('Check Permit Status'),
                ),
            ],
          ),
          if (_requestStatus != null) ...[
            const SizedBox(height: 16),
            Text(
              'Request Status: $_requestStatus',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(_requestStatus),
              ),
            ),
            if (_requestId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Request ID: $_requestId',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ],
      ),
    );
  }
}


// Service to handle permit requests using a mock API
// Service to handle permit requests using a mock API
class AbsherNafathService {
  final String _permitRequestUrl = dotenv.env['MOCK_PERMIT_REQUEST_URL'] ?? '';
  final String _permitStatusUrl = dotenv.env['MOCK_PERMIT_STATUS_URL'] ?? '';

  Future<Map<String, dynamic>> requestPermit({required String nationalId, required String vehicleDetails}) async {
    if (_permitRequestUrl.isEmpty) {
      throw Exception('Mock permit request URL is missing in .env file');
    }

    final response = await http.post(
      Uri.parse(_permitRequestUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nationalId': nationalId,
        'vehicleDetails': vehicleDetails,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit permit request: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'success') {
      throw Exception('Permit request failed: ${data['message']}');
    }

    return data;
  }

  Future<Map<String, dynamic>> checkPermitStatus({required String requestId}) async {
    if (_permitStatusUrl.isEmpty) {
      throw Exception('Mock permit status URL is missing in .env file');
    }

    final url = '$_permitStatusUrl?requestId=$requestId';
    print('Checking permit status at URL: $url'); // Debug log

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    print('Status check response: ${response.statusCode} - ${response.body}'); // Debug log

    if (response.statusCode != 200) {
      throw Exception('Failed to check permit status: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'success') {
      throw Exception('Failed to retrieve permit status: ${data['message']}');
    }

    // Override the requestId in the response with the input requestId
    data['requestId'] = requestId;
    print('Final response data: $data'); // Debug log for the final data

    return data;
  }
}