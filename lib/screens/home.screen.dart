import 'package:cnlas/apiService/auth.api.dart';
import 'package:cnlas/apiService/details.api.dart';
import 'package:cnlas/models/search.model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cnlas/apiService/directions.api.dart'; // Add this


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthAPI();
  GoogleMapController? mapController;
  Position? currentPosition;
  bool isLoadingLocation = false;
  final AuthAPI _authService = AuthAPI();
  final DetailsApi _detailService = DetailsApi();
  String name = '';
  List<SearchableItem> allItems = [];
  List<SearchableItem> filteredItems = [];
  bool isLoadingData = false;
  TextEditingController searchController = TextEditingController();
  Set<Marker> markers = {};
  Set<Polyline> polylines = {}; // Add this for route lines
  BitmapDescriptor? customMarkerIcon;
  final DirectionsService _directionsService = DirectionsService(); // Add this
  bool isLoadingRoute = false; // Add this

  // Add route info
  String? routeDistance;
  String? routeDuration;

  @override
  void initState() {
    super.initState();
    _getName();
    requestLocationPermission();
    _getCurrentLocation();
    _loadSearchData();
    _loadCustomMarker();
    searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadSearchData() async {
    setState(() => isLoadingData = true);

    try {
      final data = await _detailService.getLecturersAndLocations();
      setState(() {
        allItems = data.map((item) => SearchableItem.fromJson(item)).toList();
        filteredItems = allItems;
        isLoadingData = false;
      });
    } catch (e) {
      _showMessage('Error loading data: $e');
      setState(() => isLoadingData = false);
    }
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        filteredItems = allItems;
      });
      return;
    }

    setState(() {
      filteredItems = allItems.where((item) {
        final queryWords = query.split(' ');
        final searchText = item.searchableText;
        return queryWords.any((word) => searchText.contains(word));
      }).toList();

      filteredItems.sort((a, b) {
        final aStarts = a.searchableText.startsWith(query);
        final bStarts = b.searchableText.startsWith(query);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return 0;
      });
    });
  }

  Future<void> _loadCustomMarker() async {
    try {
      customMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/marker.png',
      );
    } catch (e) {
      // Custom marker not found, will use default
      print('Custom marker not found: $e');
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _getName() async {
    final details = await _authService.getDetails();
    setState(() {
      name = details.name;
    });
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      throw Exception('Location permission denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Please enable location services');
        setState(() => isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Location permission denied');
          setState(() => isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
      });

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16,
          ),
        );
      }
    } catch (e) {
      _showMessage('Error getting location: $e');
      setState(() => isLoadingLocation = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addMarker(SearchableItem item) {
    final lat = item.location['lat'];
    final lng = item.location['lng'];
    
    if (lat == null || lng == null) return;
    
    final marker = Marker(
      markerId: MarkerId(item.id),
      position: LatLng(lat, lng),
      icon: customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(
        item.type == 'Lecturer' 
          ? BitmapDescriptor.hueBlue 
          : BitmapDescriptor.hueRed,
      ),
      infoWindow: InfoWindow(
        title: item.name,
        snippet: item.type == 'Lecturer' 
          ? item.department 
          : item.location['abbv'],
      ),
      onTap: () {
        _showDetailsBottomSheet(item);
      },
    );
    
    setState(() {
      markers.clear(); // Only one marker at a time
      markers.add(marker);
    });
    
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 18),
      );
    }
  }

  void _showDetailsBottomSheet(SearchableItem item) {
    _addMarker(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetContent(item),
    );
  }

   // UPDATED: Navigation with routing
  Future<void> _navigateToLocation(SearchableItem item) async {
    final lat = item.location['lat'];
    final lng = item.location['lng'];

    if (lat == null || lng == null) {
      _showMessage('Location coordinates not available');
      return;
    }

    if (currentPosition == null) {
      _showMessage('Current location not available. Please wait...');
      return;
    }

    setState(() {
      isLoadingRoute = true;
    });

    try {
      final destination = LatLng(lat, lng);
      final origin = LatLng(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      // Get directions from API
      final directionsData = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        mode: 'walking', // Change to 'driving', 'bicycling', or 'transit' as needed
      );

      if (directionsData != null) {
        final route = directionsData['routes'][0];
        final overviewPolyline = route['overview_polyline']['points'];
        final leg = route['legs'][0];
        
        // Decode polyline
        final polylineCoordinates = _directionsService.decodePolyline(overviewPolyline);

        // Create polyline
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        );

        setState(() {
          polylines.clear();
          polylines.add(polyline);
          routeDistance = leg['distance']['text'];
          routeDuration = leg['duration']['text'];
          isLoadingRoute = false;
        });

        // Add destination marker
        _addDestinationMarker(item, destination);

        // Adjust camera to show entire route
        _fitRouteInView(origin, destination);

        _showMessage('Route: $routeDistance, $routeDuration');
      } else {
        setState(() {
          isLoadingRoute = false;
        });
        _showMessage('Could not find route to ${item.name}');
      }
    } catch (e) {
      setState(() {
        isLoadingRoute = false;
      });
      _showMessage('Error getting directions: $e');
    }
  }

  void _addDestinationMarker(SearchableItem item, LatLng destination) {
    final marker = Marker(
      markerId: MarkerId('destination_${item.id}'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: item.name,
        snippet: '$routeDistance • $routeDuration',
      ),
    );

    setState(() {
      markers.clear();
      markers.add(marker);
    });
  }

  void _fitRouteInView(LatLng origin, LatLng destination) {
    if (mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude ? origin.latitude : destination.latitude,
        origin.longitude < destination.longitude ? origin.longitude : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude ? origin.latitude : destination.latitude,
        origin.longitude > destination.longitude ? origin.longitude : destination.longitude,
      ),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100 is padding
    );
  }

  Color getAvatarColor(String seed, {bool darker = false}) {
    final int hash = seed.hashCode;
    final baseColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];
    final color = baseColors[hash % baseColors.length];
    return darker ? color.shade700 : color.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMapLayer(),
          _buildSearchBarLayer(),
          _buildSearchResults(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  // Clear route when tapping map
  Widget _buildMapLayer() {
    return GoogleMap(
      onMapCreated: (controller) {
        mapController = controller;
      },
      onTap: (LatLng position) {
        FocusScope.of(context).unfocus();
        
        setState(() {
          markers.clear();
          polylines.clear(); // Clear route lines
          routeDistance = null;
          routeDuration = null;
        });
      },
      initialCameraPosition: CameraPosition(
        target: currentPosition != null
            ? LatLng(
                currentPosition!.latitude,
                currentPosition!.longitude,
              )
            : const LatLng(0, 0),
        zoom: 16,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      markers: markers,
      polylines: polylines, // Add polylines to map
    );
  }

  Widget _buildSearchResults() {
    if (searchController.text.isEmpty || filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 110,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];

              return ListTile(
                leading: Icon(
                  item.type == 'Lecturer' ? Icons.person : Icons.location_on,
                ),
                title: Text(item.name),
                subtitle: Text(
                  item.type == 'Lecturer'
                      ? item.department ?? ''
                      : item.location['abbv'] ?? '',
                ),
                onTap: () {
                  // REQUIREMENT 2: Dismiss keyboard
                  FocusScope.of(context).unfocus();
                  searchController.clear();
                  
                  // Show bottom sheet and add marker
                  _showDetailsBottomSheet(item);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarLayer() {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search lecturer or location',
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: CircleAvatar(
                  backgroundColor: getAvatarColor(name),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '',
                    style: TextStyle(
                      color: getAvatarColor(name, darker: true),
                      fontWeight: FontWeight.bold,
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

 // Update bottom sheet to show loading state
  Widget _buildBottomSheetContent(SearchableItem item) {
    final isLecturer = item.type == 'Lecturer';
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: getAvatarColor(item.name),
                child: Icon(
                  isLecturer ? Icons.person : Icons.location_on,
                  color: getAvatarColor(item.name, darker: true),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.type,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          if (isLecturer) ...[
            FutureBuilder<Map<String, dynamic>>(
              future: _detailService.getLecturerDetails(item.name),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Error loading details',
                    style: TextStyle(color: Colors.red[600]),
                  );
                }
                
                final data = snapshot.data!;
                final availability = data['availability'];
                final isAvailable = availability['status'] == 'AVAILABLE';
                
                return Column(
                  children: [
                    _buildDetailRow(
                      Icons.email,
                      'Email',
                      data['Email'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.school,
                      'Department',
                      data['Department'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.meeting_room,
                      'Office',
                      '${data['Office_Building']} - ${data['Office_Number']}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.circle,
                      'Availability',
                      availability['message'],
                      valueColor: isAvailable ? Colors.green : Colors.red,
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            _buildDetailRow(
              Icons.business,
              'Building',
              item.location['Office_Building'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.label,
              'Abbreviation',
              item.location['abbv'] ?? 'N/A',
            ),
          ],
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoadingRoute
                  ? null
                  : () {
                      Navigator.pop(context);
                      _navigateToLocation(item);
                    },
              icon: isLoadingRoute
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.directions),
              label: Text(isLoadingRoute ? 'Loading Route...' : 'Get Directions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}