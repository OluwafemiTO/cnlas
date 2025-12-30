import 'package:cnlas/apiService/auth.api.dart';
import 'package:cnlas/apiService/details.api.dart';
import 'package:cnlas/models/UserDetails.model.dart';
import 'package:cnlas/models/search.model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _getName();
    _getCurrentLocation();
    _loadSearchData();

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
  //   if (isLoadingLocation || currentPosition == null) {
  //   return const Center(child: CircularProgressIndicator());
  // }
    return Positioned.fill(
      child: GoogleMap( 
        onMapCreated: (controller) { 
          mapController = controller; 
        }, 
      //   initialCameraPosition: CameraPosition(
      //   target: LatLng(
      //     currentPosition!.latitude,
      //     currentPosition!.longitude,
      //   ),
      //   zoom: 16,
      // ),
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
      ),
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
}
