import 'dart:convert';
import 'package:cnlas/util/authService.util.dart';
import 'package:http/http.dart' as http;

class DetailsApi {
  final String baseUrl = "https://cnlas-api.onrender.com/api/details";
  final storage = AuthService();

  Future<int> inputDetails(
    String email,
    String department,
    String officeBuilding,
    String officeNumber,
  ) async {
    try {
      final token = await storage.getToken();
      print(token);
      final response = await http.post(
        Uri.parse("$baseUrl/user-details"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "email": email,
          "department": department,
          "officeBuilding": officeBuilding,
          "officeNumber": officeNumber,
        }),
      );

      return response.statusCode;
    } catch (err) {
      throw Exception('Failed to input details: $err');
    }
  }

  Future<List<String>> getLocationNames() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/locations"),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((item) => item['Name'] as String).toList();
        } else {
          throw Exception(jsonResponse['error']['message']);
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['error']['message'] ?? 'Failed to load locations');
      }
    } catch (err) {
      throw Exception('Failed to load locations: $err');
    }
  }

  Future<List<String>> getDepartmentNames() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/departments"),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((item) => item.toString()).toList();
        } else {
          throw Exception(jsonResponse['error']['message']);
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['error']['message'] ?? 'Failed to load departments');
      }
    } catch (err) {
      throw Exception('Failed to load departments: $err');
    }
  }

  Future<List<Map<String, dynamic>>> getLecturersAndLocations() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/lecturers-and-locations"),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((item) => item as Map<String, dynamic>).toList();
        } else {
          throw Exception(jsonResponse['error']['message']);
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['error']['message'] ?? 'Failed to load data');
      }
    } catch (err) {
      throw Exception('Failed to load lecturers and locations: $err');
    }
  }

  Future<Map<String, dynamic>> getLecturerDetails(String name) async {
    try {
      final token = await storage.getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/lecturer"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['error']['message']);
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['error']['message'] ?? 'Failed to load lecturer details');
      }
    } catch (err) {
      throw Exception('Failed to load lecturer details: $err');
    }
  }
}