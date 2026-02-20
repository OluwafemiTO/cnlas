import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _apiKey = 'AIzaSyBGThqKdvwdOM5vEvI1ATWrwzLfhqzeLEk';

  Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving',
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$mode'
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
          print('✅ Directions retrieved successfully');
          return data;
        } else {
          // Log the actual error from Google
          print('❌ Google Directions API Error:');
          print('Status: ${data['status']}');
          print('Error Message: ${data['error_message'] ?? 'No error message'}');
          print('Available Routes: ${data['routes']?.length ?? 0}');
          
          // Common error statuses:
          // ZERO_RESULTS - No route could be found
          // OVER_QUERY_LIMIT - API key quota exceeded
          // REQUEST_DENIED - API key invalid or missing
          // INVALID_REQUEST - Invalid parameters
          // UNKNOWN_ERROR - Server error
          
          throw Exception('Directions API error: ${data['status']} - ${data['error_message'] ?? "Unknown error"}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch directions: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error getting directions: $e');
      rethrow; // Rethrow to handle it in the calling function
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