import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteOption {
  final String summary;
  final String distance;
  final String duration;
  final List<LatLng> polylinePoints;
  final int durationValue; // in seconds
  final int distanceValue; // in meters

  RouteOption({
    required this.summary,
    required this.distance,
    required this.duration,
    required this.polylinePoints,
    required this.durationValue,
    required this.distanceValue,
  });
}

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _apiKey = 'AIzaSyAdeKcM86fx8I-XF7KWCzpkfad_HCfmvWE'; // Replace with your API key

  Future<List<RouteOption>?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving',
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$mode'
        '&alternatives=true' // Request alternative routes
        '&key=$_apiKey',
      );

      print('🌍 Requesting directions from API...');
      print('Origin: ${origin.latitude},${origin.longitude}');
      print('Destination: ${destination.latitude},${destination.longitude}');
      print('Mode: $mode');

      final response = await http.get(url);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('📦 API Response Status: ${data['status']}');
        
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          print('✅ Found ${routes.length} route(s)');
          
          List<RouteOption> routeOptions = [];
          
          for (int i = 0; i < routes.length; i++) {
            final route = routes[i];
            final leg = route['legs'][0];
            final overviewPolyline = route['overview_polyline']['points'];
            
            // Get route summary (via which roads/streets)
            String summary = route['summary'] ?? 'Route ${i + 1}';
            if (summary.isEmpty) {
              summary = 'Route ${i + 1}';
            }
            
            final polylinePoints = decodePolyline(overviewPolyline);
            
            routeOptions.add(RouteOption(
              summary: summary,
              distance: leg['distance']['text'],
              duration: leg['duration']['text'],
              polylinePoints: polylinePoints,
              durationValue: leg['duration']['value'],
              distanceValue: leg['distance']['value'],
            ));
          }
          
          // Sort by duration (fastest first)
          routeOptions.sort((a, b) => a.durationValue.compareTo(b.durationValue));
          
          return routeOptions;
        } else {
          print('❌ Google Directions API Error:');
          print('Status: ${data['status']}');
          print('Error Message: ${data['error_message'] ?? 'No error message'}');
          
          throw Exception('Directions API error: ${data['status']} - ${data['error_message'] ?? "Unknown error"}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch directions: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error getting directions: $e');
      rethrow;
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }
}