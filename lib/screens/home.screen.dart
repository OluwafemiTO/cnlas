import 'dart:async';

import 'package:cnlas/apiService/auth.api.dart';
import 'package:cnlas/apiService/details.api.dart';
import 'package:cnlas/apiService/directions.api.dart';
import 'package:cnlas/models/search.model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

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
  final DirectionsService _directionsService = DirectionsService();
  String name = '';
  List<SearchableItem> allItems = [];
  List<SearchableItem> filteredItems = [];
  bool isLoadingData = false;
  TextEditingController searchController = TextEditingController();
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  BitmapDescriptor? customMarkerIcon;
  bool isLoadingRoute = false;
  
  // Route options
  List<RouteOption>? availableRoutes;
  int? selectedRouteIndex;
  
  // Navigation state
  bool isNavigating = false;
  SearchableItem? navigationTarget;
  StreamSubscription<Position>? positionStream;
  LatLng? destinationLatLng;
  
  String? routeDistance;
  String? routeDuration;
  double? remainingDistance; // in meters
  
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
      print('Custom marker not found: $e');
    }
  }

  // @override
  // void dispose() {
  //   searchController.removeListener(_onSearchChanged);
  //   searchController.dispose();
  //   super.dispose();
  // }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        if (!isNavigating) {
          _showDetailsBottomSheet(item);
        }
      },
    );
    
    setState(() {
      markers.clear();
      markers.add(marker);
    });
    
    if (mapController != null && !isNavigating) {
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
      isDismissible: !isNavigating,
      enableDrag: !isNavigating,
      builder: (context) => _buildBottomSheetContent(item),
    );
  }

  // Start live navigation
  void _startNavigation() {
    if (currentPosition == null || destinationLatLng == null) return;

    setState(() {
      isNavigating = true;
    });

    // Listen to position changes
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        currentPosition = position;
      });

      _updateNavigationRoute(position);
      _checkArrival(position);
    });
  }

  void _updateNavigationRoute(Position position) async {
    if (destinationLatLng == null || availableRoutes == null) return;

    final origin = LatLng(position.latitude, position.longitude);

    // Calculate remaining distance
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destinationLatLng!.latitude,
      destinationLatLng!.longitude,
    );

    setState(() {
      remainingDistance = distance;
    });

    // Update route if moved significantly (every ~50 meters)
    if (distance > 50 && selectedRouteIndex != null) {
      try {
        final routes = await _directionsService.getDirections(
          origin: origin,
          destination: destinationLatLng!,
          mode: 'walking',
        );

        if (routes != null && routes.isNotEmpty) {
          setState(() {
            availableRoutes = routes;
          });
          _redrawRoute();
        }
      } catch (e) {
        print('Error updating route: $e');
      }
    }

    // Keep camera following user
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(origin),
      );
    }
  }

  void _checkArrival(Position position) {
    if (destinationLatLng == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destinationLatLng!.latitude,
      destinationLatLng!.longitude,
    );

    // If within 20 meters of destination
    if (distance < 20) {
      _arriveAtDestination();
    }
  }

  void _arriveAtDestination() {
    _showMessage('🎉 You have arrived at your destination!');
    _stopNavigation();
  }

  void _stopNavigation() {
    positionStream?.cancel();
    positionStream = null;

    setState(() {
      isNavigating = false;
      navigationTarget = null;
      destinationLatLng = null;
      availableRoutes = null;
      selectedRouteIndex = null;
      remainingDistance = null;
      polylines.clear();
      markers.clear();
    });
  }

  void _redrawRoute() {
    if (availableRoutes == null || selectedRouteIndex == null) return;

    polylines.clear();

    for (int i = 0; i < availableRoutes!.length; i++) {
      final route = availableRoutes![i];
      final isSelected = i == selectedRouteIndex;
      
      polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          points: route.polylinePoints,
          color: isSelected ? Colors.blue : Colors.grey,
          width: isSelected ? 6 : 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          patterns: isSelected 
            ? []
            : [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
    }

    setState(() {});
  }

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
      availableRoutes = null;
      selectedRouteIndex = null;
      navigationTarget = item;
      destinationLatLng = LatLng(lat, lng);
    });

    try {
      final destination = LatLng(lat, lng);
      final origin = LatLng(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      print('🗺️ Getting routes...');

      final routes = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        mode: 'walking',
      );

      if (routes != null && routes.isNotEmpty) {
        setState(() {
          availableRoutes = routes;
          selectedRouteIndex = 0;
          isLoadingRoute = false;
        });

        _displayRoute(0, item, destination);
        _startNavigation();
        
        if (routes.length > 1) {
          _showRouteSelectionSheet(item, destination);
        }
      } else {
        setState(() {
          isLoadingRoute = false;
        });
        _showMessage('No route found to ${item.name}');
      }
    } catch (e) {
      setState(() {
        isLoadingRoute = false;
      });
      print('❌ Error: $e');
      _showMessage('Error getting directions: ${e.toString()}');
    }
  }

  void _displayRoute(int routeIndex, SearchableItem item, LatLng destination) {
    if (availableRoutes == null || routeIndex >= availableRoutes!.length) return;

    final selectedRoute = availableRoutes![routeIndex];
    
    polylines.clear();

    for (int i = 0; i < availableRoutes!.length; i++) {
      final route = availableRoutes![i];
      final isSelected = i == routeIndex;
      
      polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          points: route.polylinePoints,
          color: isSelected ? Colors.blue : Colors.grey,
          width: isSelected ? 6 : 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          patterns: isSelected 
            ? []
            : [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
    }

    setState(() {
      selectedRouteIndex = routeIndex;
      routeDistance = selectedRoute.distance;
      routeDuration = selectedRoute.duration;
    });

    _addDestinationMarker(item, destination);
    
    if (!isNavigating) {
      _fitRouteInView(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        destination,
      );
    }
  }

  void _showRouteSelectionSheet(SearchableItem item, LatLng destination) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: !isNavigating,
      enableDrag: !isNavigating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose a route',
                  style: TextStyle(
                    fontSize: 18,
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
            ...availableRoutes!.asMap().entries.map((entry) {
              final index = entry.key;
              final route = entry.value;
              final isSelected = index == selectedRouteIndex;
              
              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.blue : Colors.grey,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    route.summary,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('${route.duration} (${route.distance})'),
                  trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                  onTap: () {
                    setState(() {
                      selectedRouteIndex = index;
                    });
                    _displayRoute(index, item, destination);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _addDestinationMarker(SearchableItem item, LatLng destination) {
    final marker = Marker(
      markerId: MarkerId('destination_${item.id}'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: item.name,
        snippet: remainingDistance != null 
          ? '${(remainingDistance! / 1000).toStringAsFixed(1)} km away'
          : '$routeDistance • $routeDuration',
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
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
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
          if (!isNavigating) _buildSearchBarLayer(),
          if (!isNavigating) _buildSearchResults(),
          if (isNavigating) _buildNavigationInfo(),
          if (availableRoutes != null && availableRoutes!.length > 1 && !isNavigating)
            _buildRouteToggleButton(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isNavigating)
            FloatingActionButton(
              heroTag: 'stop',
              onPressed: _showStopNavigationDialog,
              backgroundColor: Colors.red,
              child: const Icon(Icons.close),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _showStopNavigationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Navigation'),
        content: const Text('Are you sure you want to stop navigation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopNavigation();
            },
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationInfo() {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.navigation, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      navigationTarget?.name ?? 'Navigating...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          remainingDistance != null 
                            ? _formatDistance(remainingDistance!)
                            : routeDistance ?? '--',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Est. Time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          routeDuration ?? '--',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteToggleButton() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: () {
          if (navigationTarget != null && destinationLatLng != null) {
            _showRouteSelectionSheet(navigationTarget!, destinationLatLng!);
          }
        },
        icon: const Icon(Icons.alt_route),
        label: Text('${availableRoutes!.length} routes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildMapLayer() {
    return GoogleMap(
      onMapCreated: (controller) {
        mapController = controller;
      },
      onTap: isNavigating ? null : (LatLng position) {
        FocusScope.of(context).unfocus();
        
        // Only clear if not navigating
        if (!isNavigating) {
          setState(() {
            markers.clear();
            polylines.clear();
            availableRoutes = null;
            selectedRouteIndex = null;
            routeDistance = null;
            routeDuration = null;
          });
        }
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
      polylines: polylines,
      zoomControlsEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
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
                  FocusScope.of(context).unfocus();
                  searchController.clear();
                  
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
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
              label: Text(isLoadingRoute ? 'Loading Routes...' : 'Start Navigation'),
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