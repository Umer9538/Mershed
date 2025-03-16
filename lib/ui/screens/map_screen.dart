import 'package:flutter/material.dart';
import 'package:mershed/core/services/map_service.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late flutter_map.MapController _mapController;
  Set<flutter_map.Marker> _markers = {};
  bool _isLoading = true;
  String _currentMapType = 'standard';
  final List<String> _mapStyles = ['Standard', 'Satellite', 'Terrain', 'Hybrid'];
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _mapController = flutter_map.MapController();
    _loadMarkers();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _markers = await MapService().getMarkers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading map data: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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

  /*void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
  }*/

  /*void _setMapStyle() async {
    // You can load custom map styles from assets
    // String mapStyle = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
    // _mapController.setMapStyle(mapStyle);
  }*/

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
    if (_isSearchVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
      _searchController.clear();
    }
  }

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        try {
          final latlong.LatLng searchResult = await MapService().searchLocation(query);
          _mapController.move(searchResult, 15);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Location not found'),
                backgroundColor: Colors.amber[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    });
  }
  /*void _changeMapType(int index) {
    setState(() {
      switch (index) {
        case 0:
          _currentMapType = MapType.normal;
          break;
        case 1:
          _currentMapType = MapType.satellite;
          break;
        case 2:
          _currentMapType = MapType.terrain;
          break;
        case 3:
          _currentMapType = MapType.hybrid;
          break;
      }
    });
  }*/
  void _changeMapType(int index) {
    setState(() {
      _currentMapType = _mapStyles[index].toLowerCase();
    });
  }

  void _goToCurrentLocation() async {
    try {
      final latlong.LatLng currentLocation = await MapService().getCurrentLocation();
      _mapController.move(currentLocation, 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not access current location'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildAppBar(theme),
      ),
      body: Stack(
        children: [
          flutter_map.FlutterMap(
            mapController: _mapController,
            options: flutter_map.MapOptions(
              center: MapService.defaultLocation,
              zoom: 10,
              onTap: (_, __) {
                if (_isSearchVisible) _toggleSearch();
              },
              onPositionChanged: (_, __) {
                setState(() => _showControls = false);
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) setState(() => _showControls = true);
                });
              },
            ),
            children: [
              flutter_map.TileLayer(
                urlTemplate: _getTileUrlTemplate(),
                userAgentPackageName: 'com.example.mershed',
              ),
              flutter_map.MarkerLayer(markers: _markers.toList() as List<flutter_map.Marker>),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          _buildSearchBar(theme),
          _buildMapStyleSelector(theme),
          _buildControlButtons(theme),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: _goToCurrentLocation,
          mini: false,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 4,
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
      title: const Text(
        'Explore',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 22,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _toggleSearch,
          tooltip: 'Search location',
        ),
        IconButton(
          icon: const Icon(Icons.layers_outlined, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => _buildMapTypeSelector(theme),
              backgroundColor: Colors.transparent,
              elevation: 0,
            );
          },
          tooltip: 'Map type',
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return AnimatedPositioned(
      top: _isSearchVisible ? 76 : -60,
      left: 16,
      right: 16,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search for a location',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: _onSearch,
                  onSubmitted: _onSearch,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  _toggleSearch();
                },
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapTypeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Map Type',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      _changeMapType(index);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _mapStyles[index].toLowerCase() == _currentMapType
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: AssetImage('assets/images/map_${_mapStyles[index].toLowerCase()}.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_mapStyles[index]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMapStyleSelector(ThemeData theme) {
    return AnimatedPositioned(
      bottom: 100,
      right: 16,
      duration: const Duration(milliseconds: 200),
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _mapStyles.length,
                    (index) => InkWell(
                  onTap: () => _changeMapType(index),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _currentMapType == _mapStyles[index].toLowerCase()
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                      border: index == _mapStyles.length - 1
                          ? null
                          : Border(
                        bottom: BorderSide(
                          color: theme.dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      _mapStyles[index][0],
                      style: TextStyle(
                        fontWeight: _currentMapType == _mapStyles[index].toLowerCase()
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentMapType == _mapStyles[index].toLowerCase()
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    return Positioned(
      bottom: 100,
      left: 16,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _mapController.move(_mapController.center, _mapController.zoom + 1),
                tooltip: 'Zoom in',
              ),
              Container(height: 1, width: 24, color: theme.dividerColor),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => _mapController.move(_mapController.center, _mapController.zoom - 1),
                tooltip: 'Zoom out',
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _getTileUrlTemplate() {
    switch (_currentMapType) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'hybrid':
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'; // Hybrid approximated
      case 'standard':
      default:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }
}