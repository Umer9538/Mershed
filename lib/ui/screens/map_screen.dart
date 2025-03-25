import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mershed/core/services/map_service.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
const MapScreen({super.key});

@override
State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
late GoogleMapController _mapController;
Set<Marker> _markers = {};
Set<Polyline> _polylines = {};
bool _isLoading = true;
String _currentMapType = 'standard';
final List<String> _mapStyles = ['Standard', 'Satellite', 'Terrain', 'Hybrid'];
bool _isSearchVisible = false;
final TextEditingController _searchController = TextEditingController();
Timer? _debounce;
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
late AnimationController _animationController;
bool _showControls = true;
bool _isOfflineMode = false;

@override
void initState() {
super.initState();
_animationController = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 300),
);
_loadMarkers();
}

@override
void dispose() {
_searchController.dispose();
_debounce?.cancel();
_animationController.dispose();
_mapController.dispose();
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

void _onMapCreated(GoogleMapController controller) {
_mapController = controller;
}

void _toggleSearch() {
setState(() {
_isSearchVisible = !_isSearchVisible;
});
if (_isSearchVisible) {
_animationController.forward();
} else {
_animationController.reverse();
_searchController.clear();
_polylines.clear();
_loadMarkers();
}
}

void _onSearch(String query) {
if (_debounce?.isActive ?? false) _debounce?.cancel();
_debounce = Timer(const Duration(milliseconds: 500), () async {
if (query.isNotEmpty) {
try {
final startLocation = await MapService().getCurrentLocation();
final endLocation = await MapService().searchLocation(query);
final routePoints = await MapService().getDirections(startLocation, endLocation);
setState(() {
_markers = {
Marker(
markerId: const MarkerId('start'),
position: startLocation,
icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
),
Marker(
markerId: const MarkerId('end'),
position: endLocation,
icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
),
};
_polylines = {
Polyline(
polylineId: const PolylineId('route'),
points: routePoints,
color: Colors.blue,
width: 4,
),
};
_mapController.animateCamera(CameraUpdate.newLatLngZoom(endLocation, 15));
});
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: const Text('Location not found or navigation failed'),
backgroundColor: Colors.amber[700],
behavior: SnackBarBehavior.floating,
),
);
}
}
}
});
}

void _changeMapType(int index) {
setState(() {
_currentMapType = _mapStyles[index].toLowerCase();
_mapController.setMapStyle(_currentMapType == 'standard'
? null
    : _currentMapType == 'satellite'
? '[{"featureType": "all", "elementType": "geometry", "stylers": [{"visibility": "off"}]},{"featureType": "landscape", "elementType": "geometry", "stylers": [{"visibility": "on"}]}]'
    : _currentMapType == 'terrain'
? '[{"featureType": "all", "elementType": "geometry", "stylers": [{"visibility": "simplified"}]},{"featureType": "landscape", "elementType": "geometry", "stylers": [{"visibility": "on"}]}]'
    : null);
});
}

void _goToCurrentLocation() async {
try {
final currentLocation = await MapService().getCurrentLocation();
_mapController.animateCamera(CameraUpdate.newLatLngZoom(currentLocation, 15));
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

Future<void> _toggleOfflineMode() async {
if (!_isOfflineMode) {
final route = await MapService().getPredefinedRoute('riyadh_to_jeddah');
setState(() {
_isOfflineMode = true;
_polylines = {
Polyline(
polylineId: const PolylineId('offline_route'),
points: route,
color: Colors.blue,
width: 4,
),
};
_markers = {
Marker(
markerId: const MarkerId('start_offline'),
position: route.first,
icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
),
Marker(
markerId: const MarkerId('end_offline'),
position: route.last,
icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
),
};
_mapController.animateCamera(CameraUpdate.newLatLngZoom(route.first, 10));
});
} else {
setState(() {
_isOfflineMode = false;
_polylines.clear();
_loadMarkers();
});
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
GoogleMap(
initialCameraPosition: const CameraPosition(
target: MapService.defaultLocation,
zoom: 10,
),
onMapCreated: _onMapCreated,
markers: _markers,
polylines: _polylines,
mapType: _currentMapType == 'satellite'
? MapType.satellite
    : _currentMapType == 'terrain'
? MapType.terrain
    : _currentMapType == 'hybrid'
? MapType.hybrid
    : MapType.normal,
onTap: (_) {
if (_isSearchVisible) _toggleSearch();
},
onCameraMove: (_) {
setState(() => _showControls = false);
Future.delayed(const Duration(milliseconds: 200), () {
if (mounted) setState(() => _showControls = true);
});
},
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
floatingActionButton: Column(
mainAxisAlignment: MainAxisAlignment.end,
children: [
AnimatedOpacity(
opacity: _showControls ? 1.0 : 0.0,
duration: const Duration(milliseconds: 200),
child: FloatingActionButton(
heroTag: 'current_location_fab', // Unique tag
onPressed: _goToCurrentLocation,
mini: false,
backgroundColor: theme.colorScheme.primary,
foregroundColor: theme.colorScheme.onPrimary,
elevation: 4,
child: const Icon(Icons.my_location),
),
),
const SizedBox(height: 16),
AnimatedOpacity(
opacity: _showControls ? 1.0 : 0.0,
duration: const Duration(milliseconds: 200),
child: FloatingActionButton(
heroTag: 'offline_mode_fab', // Unique tag
onPressed: _toggleOfflineMode,
mini: false,
backgroundColor: theme.colorScheme.primary,
foregroundColor: theme.colorScheme.onPrimary,
elevation: 4,
child: Icon(_isOfflineMode ? Icons.wifi_off : Icons.wifi),
),
),
],
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
onPressed: () => _mapController.animateCamera(CameraUpdate.zoomIn()),
tooltip: 'Zoom in',
),
Container(height: 1, width: 24, color: theme.dividerColor),
IconButton(
icon: const Icon(Icons.remove),
onPressed: () => _mapController.animateCamera(CameraUpdate.zoomOut()),
tooltip: 'Zoom out',
),
],
),
),
),
);
}
}