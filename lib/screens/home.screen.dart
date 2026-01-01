import 'package:cnlas/apiService/auth.api.dart';
import 'package:cnlas/apiService/details.api.dart';
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
  String name = '';
  List<SearchableItem> allItems = [];
  List<SearchableItem> filteredItems = [];
  bool isLoadingData = false;
  TextEditingController searchController = TextEditingController();
   // Add these for markers
  Set<Marker> markers = {};
  BitmapDescriptor? customMarkerIcon;

  @override
  void initState() {
    super.initState();
    _getName();
    requestLocationPermission();
    _getCurrentLocation();
    _loadSearchData();
    _loadCustomMarker(); // Load custom marker icon


    // Listen to search input
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
        // Split query into words for better matching
        final queryWords = query.split(' ');
        final searchText = item.searchableText;

        // Match if ANY word in query is found in searchable text
        return queryWords.any((word) => searchText.contains(word));
      }).toList();

      // Sort by relevance (items that start with query first)
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
    customMarkerIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/marker.png', // Optional: add your own marker icon
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _getName() async {
    final details = await _authService.getDetails();
    name = details.name;
  }


  Future<void> requestLocationPermission() async {
  final status = await Permission.location.request();

  if (!status.isGranted) {
    throw Exception('Location permission denied');
  }
}


  // Get user's current location
  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Please enable location services');
        setState(() => isLoadingLocation = false);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Location permission denied');
          setState(() => isLoadingLocation = false);
          return;
        }
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition();
      print("Lat: ${position.latitude}, Lng: ${position.longitude}");

      setState(() {
        currentPosition = position;
        isLoadingLocation = false;
      });

      // Move camera to current location
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

  Future<void> _handleLogout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
      markers.clear(); // Clear previous markers
      markers.add(marker);
    });
    
    // Animate camera to marker
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 18),
      );
    }
  }

  void _showDetailsBottomSheet(SearchableItem item) {
    // Add marker when showing bottom sheet
    _addMarker(item);


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetContent(item),
    );
  }

  void _navigateToLocation(SearchableItem item) {
    final lat = item.location['lat'];
    final lng = item.location['lng'];

    if (lat != null && lng != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 18),
      );
      
      // TODO: Add route drawing logic here
      _showMessage('Navigating to ${item.name}');
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
          _buildSearchBarLayer(),
          _buildSearchResults(), // already done
        ],
      ),
      // Floating button to recenter on location
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildMapLayer() {
    return GoogleMap( 
      onMapCreated: (controller) { 
        mapController = controller; 
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
      markers: markers, // Add this line to display markers
    );
  }

  Widget _buildSearchResults() {
    if (searchController.text.isEmpty || filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 110, // below search bar
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
                  final lat = item.location['lat'];
                  final lng = item.location['lng'];

                  if (lat != null && lng != null && mapController != null) {
                    mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 18),
                    );
                  }

                  searchController.clear();
                  FocusScope.of(context).unfocus();

                  // Show bottom sheet instead of just navigating
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
                  print("hello");
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
          // Drag handle
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
          
          // Icon and Type
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
          
          // Details section
          if (isLecturer) ...[
            // Fetch and display availability
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
          
          // Directions button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToLocation(item);
              },
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
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
