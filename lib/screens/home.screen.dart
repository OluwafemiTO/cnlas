import 'package:cnlas/apiService/auth.api.dart';
import 'package:cnlas/models/UserDetails.model.dart';
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
  String name = '';
  

  @override
  void initState() {
    super.initState();
    _getName();
    _getCurrentLocation();

  }

  Future<void> _getName() async{
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleLogout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  TextEditingController searchController = TextEditingController();

  void _onSearch() async {
   
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
    final theme = Theme.of(context);
    double screenHeight = MediaQuery.heightOf(context);
    



    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Home'),
      //   actions: [
      //     if (isLoadingLocation)
      //       const Center(
      //         child: Padding(
      //           padding: EdgeInsets.all(16.0),
      //           child: SizedBox(
      //             width: 20,
      //             height: 20,
      //             child: CircularProgressIndicator(strokeWidth: 2),
      //           ),
      //         ),
      //       ),
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: _handleLogout,
      //     ),
      //   ],
      // ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
              
              // If we already have location, move camera
              if (currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(currentPosition!.latitude, currentPosition!.longitude),
                    16,
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(6.5244, 3.3792), // Default: Lagos
              zoom: 12,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  filled: true,
                  hintText: 'Search location...',
                  prefixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _onSearch,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: (){print("hello");},
                      child: CircleAvatar(
                        backgroundColor: getAvatarColor(name),
                        child: Text(
                          name != null && name!.isNotEmpty ? name![0].toUpperCase() : '?',
                          style: TextStyle(
                            color: getAvatarColor(name, darker: true),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )

                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  _onSearch();
                },
              ),
            ),
          ),
        ],
      ),
      // Floating button to recenter on location
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}